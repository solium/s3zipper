require "s3_zipper/version"
require 's3_zipper/progress'
require "s3_zipper/client"
require "zip"

class S3Zipper
  attr_accessor :client, :options

  # @param [String] bucket - bucket that files exist in
  # @param [Hash] options - options for zipper
  # @option options [Boolean] :progress - toggles progress tracking
  # @return [S3Zipper]
  def initialize bucket, options = {}
    @options = options
    @client  = Client.new(bucket, options)
  end

  # Zips files from s3 to a local zip
  # @param [Array] keys - Array of s3 keys to zip
  # @param [String, File] file - Filename or file object for the zip, defaults to a random string
  # @return [Hash]
  def zip_to_local_file(keys, file: SecureRandom.hex)
    file = file.is_a?(File) ? file : File.open("#{file}.zip", 'w')
    zip keys, file.path do |progress|
      yield progress if block_given?
    end
  end

  # Zips files from s3 to a temporary zip
  # @param [Array] keys - Array of s3 keys to zip
  # @param [String, File] filename - Name of file, defaults to a random string
  # @return [Hash]
  def zip_to_tempfile(keys, filename: SecureRandom.hex, cleanup: false)
    zipfile = Tempfile.new([filename, '.zip'])
    result  = zip(keys, zipfile.path) { |progress| yield(zipfile, progress) if block_given? }
    zipfile.unlink if cleanup
    result
  end

  # Zips files from s3 to a temporary file, pushes that to s3, and then cleans up
  # @param [Array] keys - Array of s3 keys to zip
  # @param [String, File] filename - Name of file, defaults to a random string
  # @param [String] path - path for file in s3
  # @return [Hash]
  def zip_to_s3 keys, filename: SecureRandom.hex, path: nil
    filename = "#{path ? "#{path}/" : ''}#{filename}.zip"
    result   = zip_to_tempfile(keys, filename: filename, cleanup: false) do |_, progress|
      yield(progress) if block_given?
    end
    client.upload(result[:filename], filename)
    result[:filename] = filename
    result
  end

  private

  # @param [Array] keys - Array of s3 keys to zip
  # @param [String] path - path to zip
  # @yield [progress]
  # @return [Hash]
  def zip(keys, path)
    failed, successful = client.download_keys keys
    Zip::File.open(path, Zip::File::CREATE) do |zipfile|
      pb = Progress.new(enabled: options[:progress], format: "%e %c/%C %t", total: keys.count, length: 80, autofinish: false)
      successful.each do |key, file|
        pb.increment
        pb.update 'title', "Adding #{key} to #{path}"
        next if file.nil?
        yield(pb.progress) if block_given?
        zipfile.add(key, file.path)
      end
      pb.finish(title: "Zipped files to #{path}")
    end
    successful.each { |_, temp| temp.unlink }
    {
      filename: path,
      zipped:   successful.map(&:first),
      failed:   failed.map(&:first)
    }
  end
end

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

  def zip_to_local_file(keys, file: SecureRandom.hex)
    file = file.is_a?(File) ? file : File.open("#{file}.zip", 'w')
    zip keys, file.path do |progress|
      yield progress if block_given?
    end
  end

  def zip_to_tempfile(keys, filename: SecureRandom.hex)
    zipfile = Tempfile.new([filename, '.zip'])
    result  = zip(keys, zipfile.path)
    yield(zipfile, result) if block_given?
    zipfile.unlink
    result
  end

  def zip_to_s3 keys, filename: SecureRandom.hex, path: nil
    zip_to_tempfile(keys, filename: filename) do |zipfile, result|
      result[:filename] = "#{path ? "#{path}/" : ''}#{filename}.zip"
      client.upload(zipfile.path, result[:filename])
    end
  end

  private

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

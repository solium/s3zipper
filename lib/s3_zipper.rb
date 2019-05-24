# frozen_string_literal: true

require 's3_zipper/version'
require 's3_zipper/progress'
require 's3_zipper/client'
require 'zip'

class S3Zipper
  attr_accessor :client, :options, :progress

  # @param [String] bucket - bucket that files exist in
  # @param [Hash] options - options for zipper
  # @option options [Boolean] :progress - toggles progress tracking
  # @return [S3Zipper]
  def initialize(bucket, options = {})
    @options  = options
    @client   = Client.new(bucket, options)
    @progress = Progress.new(enabled: options[:progress], format: '%e %c/%C %t', total: nil, length: 80, autofinish: false)
  end

  # Zips files from s3 to a local zip
  # @param [Array] keys - Array of s3 keys to zip
  # @param [String, File] file - Filename or file object for the zip, defaults to a random string
  # @return [Hash]
  def zip_to_local_file(keys, file: SecureRandom.hex, &block)
    file = file.is_a?(File) ? file : File.open("#{file}.zip", 'w')
    zip(keys, file.path, &block)
  end

  # Zips files from s3 to a temporary zip
  # @param [Array] keys - Array of s3 keys to zip
  # @param [String, File] filename - Name of file, defaults to a random string
  # @return [Hash]
  def zip_to_tempfile(keys, filename: SecureRandom.hex, cleanup: false, &block)
    zipfile = Tempfile.new([filename, '.zip'])
    result  = zip(keys, zipfile.path, &block)
    zipfile.unlink if cleanup
    result
  end

  # Zips files from s3 to a temporary file, pushes that to s3, and then cleans up
  # @param [Array] keys - Array of s3 keys to zip
  # @param [String, File] filename - Name of file, defaults to a random string
  # @param [String] path - path for file in s3
  # @return [Hash]
  def zip_to_s3(keys, filename: SecureRandom.hex, path: nil, s3_options: {}, &block)
    filename = "#{path ? "#{path}/" : ''}#{filename}.zip"
    result   = zip_to_tempfile(keys, filename: filename, cleanup: false, &block)
    client.upload(result.delete(:filename), filename, options: s3_options)
    result[:key] = filename
    result[:url] = client.get_url(result[:key])
    result
  end

  private

  # @param [Array] keys - Array of s3 keys to zip
  # @param [String] path - path to zip
  # @yield [progress]
  # @return [Hash]
  def zip(keys, path)
    total = progress.total || 0
    total += keys.size
    progress.update_attrs total: total, title: "Zipping Keys to #{path}"
    Zip::File.open(path, Zip::File::CREATE) do |zipfile|
      @failed, @successful = client.download_keys keys do |file, key|
        progress.increment title: "Zipping #{key} to #{path}"
        yield(zipfile, progress) if block_given?
        next if file.nil?

        zipfile.add(File.basename(key), file.path)
      end
    end
    @successful.each { |_, temp| temp.unlink }
    {
      filename: path,
      filesize: File.size(path),
      zipped:   @successful.map(&:first),
      failed:   @failed.map(&:first)
    }
  end
end

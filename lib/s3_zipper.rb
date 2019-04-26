require "s3_zipper/version"
require "s3_zipper/bucket_util"
require "s3_zipper/zip_file"
require 's3_zipper/progress'

class S3Zipper
  attr_accessor :keys, :bucket, :options, :zipfile

  def initialize bucket, options = {}
    @options = options
    @bucket  = BucketUtil.new(bucket, options)
  end

  def zip_files keys, filename: SecureRandom.hex
    self.zipfile = ZipFile.new(filename)
    self.keys    = keys
    pb           = Progress.new(enabled: options[:progress], format: "'#{zipfile.path}' %e %p% %c/%C %t", total: keys.count, length: 80, autofinish: false)
    keys.each_with_object({ zipped: [], failed: [] }) do |key, hash|
      pb.update 'title', "Key: #{key}"
      bucket.download_to_tempfile(key) do |file|
        hash[:failed] << key if file.nil?
        zipfile.add(key, file)
        hash[:zipped] << file
      end
      pb.increment
      yield(pb.progress) if block_given?
    end
    pb.finish(title: '')
    bucket.upload(zipfile.path, zipfile.filename)
    results
  end

  private

  def results
    { filename: zipfile.filename }.merge(%i[zipped failed].zip(keys).to_h)
  end
end

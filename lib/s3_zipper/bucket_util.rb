require 's3_zipper/progress'

class S3Zipper
  class BucketUtil
    attr_accessor :bucket_name, :s3, :options

    def initialize bucket_name, options = {}
      @bucket_name = bucket_name
      @s3          = Aws::S3::Client.new
      @options     = options
    end

    def download key
      s3.get_object bucket: bucket_name, key: key
    end

    def download_to_file key, target
      begin
        s3.get_object({ bucket: bucket_name, key: key }, target: target)
      rescue StandardError => e
        return nil
      end
      target
    end

    def download_to_tempfile key
      temp = Tempfile.new
      temp.binmode
      temp = download_to_file key, temp
      yield(temp) if block_given?
      temp
    ensure
      temp&.unlink
    end

    def upload local_path, repo_path
      pb = Progress.new(enabled: options[:progress], format: '%t %i', title: "Uploading '#{local_path}' to '#{repo_path}'", length: 120)
      Aws::S3::Resource.new.bucket(bucket_name).object(repo_path).upload_file local_path
      pb.finish(title: "Uploaded '#{local_path}' to '#{repo_path}'")
    end
  end
end
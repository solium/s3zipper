require 'aws-sdk-s3'
class S3Zipper
  class Client
    attr_accessor :bucket_name, :s3, :options

    def initialize bucket_name, options = {}
      @bucket_name = bucket_name
      @s3          = options[:client] || Aws::S3::Client.new
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
      s3.put_object(bucket: bucket_name, key: repo_path, body: File.open(local_path).read)
      pb.finish(title: "Uploaded '#{local_path}' to '#{repo_path}'")
    end
  end
end

require 'aws-sdk-s3'

class S3Zipper
  class Client
    attr_accessor :bucket_name, :client, :options, :resource, :pb

    # @param [String] bucket_name - bucket that files exist in
    # @param [Hash] options - options for zipper
    # @option options [Boolean] :progress - toggles progress tracking
    # @return [S3Zipper::Client]
    def initialize bucket_name, options = {}
      @bucket_name = bucket_name
      @client      = options[:client] || ::Aws::S3::Client.new
      @resource    = options[:resource] || ::Aws::S3::Resource.new
      @options     = options
      @pb          = Progress.new(enabled: options[:progress], format: "%e %c/%C %t", total: nil, length: 80, autofinish: false)
    end

    def download_keys keys
      pb.reset(total: keys.count, title: 'Downloading Keys', format: "%e %c/%C %t")
      keys = keys.map do |key|
        pb.increment
        pb.update 'title', "Downloading Key: #{key}"
        temp = download_to_tempfile(key, cleanup: false)
        [key, temp]
      end
      keys = keys.partition { |_, temp| temp.nil? }
      pb.finish(title: 'Downloaded Keys', format: '%e %c/%C %t')
      keys
    end

    def download key
      client.get_object bucket: bucket_name, key: key
    end

    def download_to_file key, target
      begin
        client.get_object({ bucket: bucket_name, key: key }, target: target)
      rescue StandardError => e
        return nil
      end
      target
    end

    def download_to_tempfile key, cleanup: true
      temp = Tempfile.new
      temp.binmode
      temp = download_to_file key, temp
      return if temp.nil?
      yield(temp) if block_given?
      temp
    ensure
      temp&.unlink if cleanup
    end

    def get_url(key)
      resource.bucket(bucket_name).object(key).public_url
    end

    def upload local_path, repo_path
      pb     = Progress.new(enabled: options[:progress], format: '%t', title: "Uploading '#{local_path}' to '#{repo_path}'", length: 120)
      object = client.put_object(bucket: bucket_name, key: repo_path, body: File.open(local_path).read)
      pb.finish(title: "Uploaded '#{local_path}' to '#{repo_path}'")
      object
    end
  end
end

# frozen_string_literal: true

require "aws-sdk"

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
    end

    def download_keys keys, cleanup: false
      keys = keys.map do |key|
        temp = download_to_tempfile(key, cleanup: cleanup)
        yield(temp, key) if block_given?
        [key, temp]
      end
      keys.partition { |_, temp| temp.nil? }
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

    def get_url key
      resource.bucket(bucket_name).object(key).public_url
    end

    def upload local_path, repo_path, options: {}
      spinner = Spinner.new(
        enabled: options[:progress],
        title:   "Uploading zip to #{bucket_name}/#{repo_path}",
      )
      spinner.start
      object = client.put_object(options.merge!(bucket: bucket_name, key: repo_path, body: File.open(local_path).read))
      spinner.finish title: "Uploaded zip to #{bucket_name}/#{repo_path}"
      object
    end
  end
end

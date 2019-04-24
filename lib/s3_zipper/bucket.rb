require 'ruby-progressbar'
require 'zip'
module S3Zipper
  class Bucket
    attr_accessor :files, :bucket, :filename, :options

    def initialize(bucket)
      @bucket  = bucket
    end

    def zip_files(files, filename: "#{SecureRandom.hex}.zip")
      self.filename = Tempfile.new(filename).path
      self.files    = files
      progress_bar  = ProgressBar.create(format: '%t %e |%b>%i| %p% %c/%C', total: files.count, title: 'Zipping Files', length: 80)
      self.files    = files.partition do |key|
        file = download(key) do |file|
          Zip::File.open(filename, Zip::File::CREATE) do |zipfile|
            zipfile.add(key, file)
          end
        end
        yield(progress_bar&.progress, progress_bar&.total) if block_given?
        progress_bar&.increment
        file.present?
      end
      upload(filename, "#{filename}")
      results
    end

    private

    def results
      { filename: self.filename }.merge(%i[zipped failed].zip(files).to_h)
    end

    def download key, bucket = self.bucket
      begin
        temp = Tempfile.new
        temp.binmode
        Aws::S3::Client.new.get_object({ bucket: bucket, key: key }, target: temp)
      rescue StandardError => e
        return nil
      end
      block_given? ? yield(temp) : temp
    ensure
      temp.unlink
    end

    def upload local_path, repo_path, bucket = self.bucket
      Aws::S3::Resource.new.bucket(bucket).object(repo_path).upload_file local_path
    end
  end
end
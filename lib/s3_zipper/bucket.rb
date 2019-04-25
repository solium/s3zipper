require 'ruby-progressbar'
require 'zip'
module S3Zipper
  class Bucket
    attr_accessor :files, :bucket, :filename, :options

    def initialize(bucket)
      @bucket = bucket
    end

    def zip_files(files, filename: SecureRandom.hex)
      temp               = Tempfile.new([filename, '.zip'])
      self.filename      = temp.path
      self.files         = files
      progress_bar       = ProgressBar.create(format: "'#{self.filename}' %e %p% %c/%C %t", total: files.count, length: 80, autofinish: false)
      self.files         = files.partition do |key|
        progress_bar.title = "Key: #{key}"
        progress_bar.refresh
        file = download(key) do |file|
          Zip::File.open(self.filename, Zip::File::CREATE) do |zipfile|
            zipfile.add(key, file)
          end
        end
        yield(progress_bar&.progress, progress_bar&.total) if block_given?
        progress_bar&.increment
        file.present?
      end
      progress_bar.title = ''
      progress_bar.refresh
      progress_bar.finish
      upload
      temp.unlink
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

    def upload local_path: self.filename, repo_path: self.filename, bucket: self.bucket
      Aws::S3::Resource.new.bucket(bucket).object(repo_path).upload_file local_path
    end
  end
end
require 'zip'

class S3Zipper
  class ZipFile
    attr_accessor :filename, :path, :file

    def initialize filename
      @file     = Tempfile.new([filename, '.zip'])
      @filename = "#{filename}.zip"
      @path     = file.path
    end

    def cleanup
      file.unlink
    end

    def add zippath, file
      return if file.nil?
      Zip::File.open(path, Zip::File::CREATE) do |zipfile|
        zipfile.add(zippath, file)
      end
    end
  end
end
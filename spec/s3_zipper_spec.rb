# frozen_string_literal: true

RSpec.describe S3Zipper do
  before :all do
    ENV["AWS_REGION"]            = "us-west-2"
    ENV["AWS_ACCESS_KEY_ID"]     = "123456789"
    ENV["AWS_SECRET_ACCESS_KEY"] = "123456789abcdefg"
  end
  let(:fake_s3) { {} }
  let(:client) do
    client = Aws::S3::Client.new(stub_responses: true)
    client.stub_responses(
      :create_bucket, lambda { |context|
      name = context.params[:bucket]
      if fake_s3[name]
        "BucketAlreadyExists" # standalone strings are treated as exceptions
      else
        fake_s3[name] = {}
        {}
      end
    }
    )
    client.stub_responses(
      :get_object, lambda { |context|
      bucket     = context.params[:bucket]
      key        = context.params[:key]
      b_contents = fake_s3[bucket]
      if b_contents
        obj = b_contents[key]
        if obj
          { body: SecureRandom.random_bytes(1_004_979) }
        else
          "NoSuchKey"
        end
      else
        "NoSuchBucket"
      end
    }
    )
    client.stub_responses(
      :put_object, lambda { |context|
      bucket     = context.params[:bucket]
      key        = context.params[:key]
      body       = context.params[:body]
      b_contents = fake_s3[bucket]
      if b_contents
        b_contents[key] = body
        {}
      else
        "NoSuchBucket"
      end
    }
    )
    client
  end
  let!(:bucket_name) { "test" }
  let!(:zip_bucket_name) { "zip_test" }
  let!(:bucket) { client.create_bucket(bucket: bucket_name) }
  let!(:zip_bucket) { client.create_bucket(bucket: zip_bucket_name) }
  let(:keys) do
    (0..99).map do |n|
      client.put_object(bucket: bucket_name, key: n.to_s, body: n.to_s)
      n.to_s
    end
  end
  let(:fake_keys) { (100..199).map(&:to_s) }
  let(:zipper) { described_class.new(bucket_name, client: client) }
  let(:multi_bucket_zipper) { described_class.new(bucket_name, client: client, zip_bucket: zip_bucket_name) }
  it "has a version number" do
    expect(S3Zipper::VERSION).not_to be nil
  end

  describe "zips to different bucket" do
    it "zips all files" do
      result = multi_bucket_zipper.zip_to_s3(keys, filename: "test")
      expect(result).to eq(
                          key:      "test.zip",
                          url:      "https://test.s3.us-west-2.amazonaws.com/test.zip",
                          filesize: 100_536_902,
                          zipped:   keys,
                          failed:   [],
                        )
    end

    it "zips some files" do
      result = multi_bucket_zipper.zip_to_s3(keys + fake_keys, filename: "test")
      expect(result).to eq(
                          key:      "test.zip",
                          url:      "https://test.s3.us-west-2.amazonaws.com/test.zip",
                          filesize: 100_536_902,
                          zipped:   keys,
                          failed:   fake_keys,
                        )
    end

    it "zips no files" do
      result = multi_bucket_zipper.zip_to_s3(fake_keys, filename: "test")
      expect(result).to eq(
                          key:      "test.zip",
                          url:      "https://test.s3.us-west-2.amazonaws.com/test.zip",
                          filesize: 22,
                          zipped:   [],
                          failed:   fake_keys,
                        )
    end
  end

  describe "#zip_to_local_file" do
    it "handles duplicate files" do
      result = zipper.zip_to_local_file(keys + keys, file: "test")
      Zip::File.open(result[:filename]) do |zip_file|
        keys.each do |key|
          expect(zip_file.find_entry(key)).not_to be_nil
          expect(zip_file.find_entry("#{File.basename(key, ".*")}(0)#{File.extname(key)}")).not_to be_nil
        end
      end
    end

    it "zips all files" do
      result = zipper.zip_to_local_file(keys, file: "test")
      expect(result).to eq(
                          filename: "test.zip",
                          filesize: 100_536_902,
                          zipped:   keys,
                          failed:   [],
                        )
      File.delete(result[:filename])
    end

    it "zips some files" do
      result = zipper.zip_to_local_file(keys + fake_keys, file: "test")
      expect(result).to eq(
                          filename: "test.zip",
                          filesize: 100_536_902,
                          zipped:   keys,
                          failed:   fake_keys,
                        )
      File.delete(result[:filename])
    end

    it "zips no files" do
      result = zipper.zip_to_local_file(fake_keys, file: "test")
      expect(result).to eq(
                          filename: "test.zip",
                          filesize: 22,
                          zipped:   [],
                          failed:   fake_keys,
                        )
      File.delete(result[:filename])
    end
  end

  describe "#zip_to_s3" do
    it "zips all files" do
      result = zipper.zip_to_s3(keys, filename: "test")
      expect(result).to eq(
                          key:      "test.zip",
                          url:      "https://test.s3.us-west-2.amazonaws.com/test.zip",
                          filesize: 100_536_902,
                          zipped:   keys,
                          failed:   [],
                        )
    end

    it "zips some files" do
      result = zipper.zip_to_s3(keys + fake_keys, filename: "test")
      expect(result).to eq(
                          key:      "test.zip",
                          url:      "https://test.s3.us-west-2.amazonaws.com/test.zip",
                          filesize: 100_536_902,
                          zipped:   keys,
                          failed:   fake_keys,
                        )
    end

    it "zips no files" do
      result = zipper.zip_to_s3(fake_keys, filename: "test")
      expect(result).to eq(
                          key:      "test.zip",
                          url:      "https://test.s3.us-west-2.amazonaws.com/test.zip",
                          filesize: 22,
                          zipped:   [],
                          failed:   fake_keys,
                        )
    end
  end
end

RSpec.describe S3Zipper do
  let(:fake_s3) { {} }
  let(:client) do
    client = Aws::S3::Client.new(stub_responses: true)
    client.stub_responses(
      :create_bucket, ->(context) {
      name = context.params[:bucket]
      if fake_s3[name]
        'BucketAlreadyExists' # standalone strings are treated as exceptions
      else
        fake_s3[name] = {}
        {}
      end
    }
    )
    client.stub_responses(
      :get_object, ->(context) {
      bucket     = context.params[:bucket]
      key        = context.params[:key]
      b_contents = fake_s3[bucket]
      if b_contents
        obj = b_contents[key]
        if obj
          { body: SecureRandom.random_bytes(1004979) }
        else
          'NoSuchKey'
        end
      else
        'NoSuchBucket'
      end
    }
    )
    client.stub_responses(
      :put_object, ->(context) {
      bucket     = context.params[:bucket]
      key        = context.params[:key]
      body       = context.params[:body]
      b_contents = fake_s3[bucket]
      if b_contents
        b_contents[key] = body
        {}
      else
        'NoSuchBucket'
      end
    }
    )
    client
  end
  let!(:bucket_name) { 'test' }
  let!(:bucket) { client.create_bucket(bucket: bucket_name) }
  let(:keys) {
    (0..99).map do |n|
      client.put_object(bucket: bucket_name, key: n.to_s, body: n.to_s)
      n.to_s
    end
  }
  let(:fake_keys) { (100..199).map(&:to_s) }
  let(:zipper) { described_class.new(bucket_name, client: client) }
  it "has a version number" do
    expect(S3Zipper::VERSION).not_to be nil
  end

  describe "#zip_to_local_file" do
    it 'zips all files' do
      result = zipper.zip_to_local_file(keys, file: 'test')
      expect(result).to eq({
                             filename: 'test.zip',
                             filesize: 100536902,
                             zipped:   keys,
                             failed:   []
                           })
      File.delete(result[:filename])
    end

    it 'zips some files' do
      result = zipper.zip_to_local_file(keys + fake_keys, file: 'test')
      expect(result).to eq({
                             filename: 'test.zip',
                             filesize: 100536902,
                             zipped:   keys,
                             failed:   fake_keys
                           })
      File.delete(result[:filename])
    end

    it 'zips no files' do
      result = zipper.zip_to_local_file(fake_keys, file: 'test')
      expect(result).to eq({
                             filename: 'test.zip',
                             filesize: 22,
                             zipped:   [],
                             failed:   fake_keys
                           })
      File.delete(result[:filename])
    end
  end

  describe "#zip_to_s3" do
    it 'zips all files' do
      result = zipper.zip_to_s3(keys, filename: 'test')
      expect(result).to eq({
                             key:      'test.zip',
                             url:      "https://test.s3.us-west-2.amazonaws.com/test.zip",
                             filesize: 100536902,
                             zipped:   keys,
                             failed:   []
                           })
    end

    it 'zips some files' do
      result = zipper.zip_to_s3(keys + fake_keys, filename: 'test')
      expect(result).to eq({
                             key:      'test.zip',
                             url:      "https://test.s3.us-west-2.amazonaws.com/test.zip",
                             filesize: 100536902,
                             zipped:   keys,
                             failed:   fake_keys
                           })
    end

    it 'zips no files' do
      result = zipper.zip_to_s3(fake_keys, filename: 'test')
      expect(result).to eq({
                             key:      'test.zip',
                             url:      "https://test.s3.us-west-2.amazonaws.com/test.zip",
                             filesize: 22,
                             zipped:   [],
                             failed:   fake_keys
                           })
    end
  end
end

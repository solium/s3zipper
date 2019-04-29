RSpec.describe S3Zipper do
  it "has a version number" do
    expect(S3Zipper::VERSION).not_to be nil
  end

  describe "Zipps files from s3" do
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
            { body: obj }
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
    it 'zips all files' do
      result = zipper.zip_files(keys, filename: 'zipped')
      expect(result).to eq({
                             filename: 'zipped.zip',
                             zipped:   keys,
                             failed:   []
                           })
    end

    it 'zips some files' do
      result = zipper.zip_files(keys + fake_keys, filename: 'zipped')
      expect(result).to eq({
                             filename: 'zipped.zip',
                             zipped:   keys,
                             failed:   fake_keys
                           })
    end

    it 'zips no files' do
      result = zipper.zip_files(fake_keys, filename: 'zipped')
      expect(result).to eq({
                             filename: 'zipped.zip',
                             zipped:   [],
                             failed:   fake_keys
                           })

    end
  end
end

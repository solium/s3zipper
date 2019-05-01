# S3Zipper

This is a gem for zipping files stored in Amazon S3

## Installation

Add this line to your application's Gemfile:

```ruby
gem 's3_zipper'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install s3_zipper

## Usage
```ruby
require 's3_zipper'
zipper = S3Zipper.new('bucket_name')
```
### Zip to local file
```ruby
keys = ["documents/files/790/306/985/original/background-10.jpg", "documents/files/790/307/076/original/background-10.jpg"]
zipper.zip_to_local_file(keys)
# {
#   :filename=>"3dc29e9ba0a069eb5d0783f07b12e1b3.zip", 
#   :zipped=>["documents/files/790/306/985/original/background-10.jpg", "documents/files/790/307/076/original/background-10.jpg"], 
#   :failed=>[]
# }
```

### Zip to s3
```ruby
keys = ["documents/files/790/306/985/original/background-10.jpg", "documents/files/790/307/076/original/background-10.jpg"]
zipper.zip_to_s3(keys)
# {
#   :key=>"3dc29e9ba0a069eb5d0783f07b12e1b3.zip", 
#   :zipped=>["documents/files/790/306/985/original/background-10.jpg", "documents/files/790/307/076/original/background-10.jpg"], 
#   :failed=>[]
# }
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/s3_zipper. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the S3Zipper project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/s3_zipper/blob/master/CODE_OF_CONDUCT.md).

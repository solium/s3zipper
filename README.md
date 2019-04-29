# S3Zipper

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/s3_zipper`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

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
zipper = S3Zipper.new(ENV['AWS_BUCKET'])
files = ["documents/files/790/306/985/original/background-10.jpg", "documents/files/790/307/076/original/background-10.jpg", "documents/files/790/307/029/original/background-10.jpg", "documents/files/790/307/031/original/background-11.jpg", "documents/files/790/307/077/original/background-11.jpg", "documents/files/790/306/983/original/background-11.jpg", "documents/files/790/306/986/original/background-12.jpg", "documents/files/790/307/078/original/background-12.jpg", "documents/files/790/307/032/original/background-12.jpg", "documents/files/790/306/987/original/background-13.jpg"]
zipper.zip_files(files)
{
  :filename=>"3dc29e9ba0a069eb5d0783f07b12e1b3.zip", 
  :zipped=>["documents/files/790/306/985/original/background-10.jpg", "documents/files/790/307/076/original/background-10.jpg", "documents/files/790/307/029/original/background-10.jpg", "documents/files/790/307/031/original/background-11.jpg", "documents/files/790/307/077/original/background-11.jpg", "documents/files/790/306/983/original/background-11.jpg", "documents/files/790/306/986/original/background-12.jpg", "documents/files/790/307/078/original/background-12.jpg", "documents/files/790/307/032/original/background-12.jpg", "documents/files/790/306/987/original/background-13.jpg"], 
  :failed=>[]
}
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

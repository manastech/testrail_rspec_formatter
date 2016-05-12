# TestrailRspecFormatter

An RSpec formatter that sends results to [TestRail](http://www.gurock.com/testrail/)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'testrail_rspec_formatter'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install testrail_rspec_formatter

## Usage

After specs run the formatter will mark test cases of a test run as either passed, failed or retest,
depending on whether a spec passed, failed or is pending. Specs are associated with TestRail test cases
by adding a tag with the name `testrail` to them:

```ruby
describe "som test" do
  id "some spec", testrail: 1234 do # 1234 is the id of a test case
    # ...
  end
end
```

The formatter must be configured with a run name inside a project id. If a run with that name doesn't exist
it is created.

The recommended way to use this formatter is to set the run name to a project's version or tag, and only
run it on release or deploy versions (using the disabled configuration option).

### Configuration

In addition to the configuration specified below, the formatter is only ran when passed to rspec
via a `--formatter` argument (which can be in the `.rspec` file):

```
rspec spec --format TestrailRspecFormatter::Formatter
```

To have it ran in addition to the default progress (dots) formatter, execute:

```
rspec spec --format progress --format TestrailRspecFormatter::Formatter
```

Configure it via `ENV` variables or `RSpec.configure` (or with a mix of them).

### Via ENV

* TESTRAIL_FORMATTER_PROJECT_ID: (required) the id of the TestRail project
* TESTRAIL_FORMATTER_RUN_NAME: (required) the name of the run to target
* TESTRAIL_FORMATTER_URL: (required) the URL to target (`"https://your-user.testrail.com"``)
* TESTRAIL_FORMATTER_USER: (required) your TestRail user
* TESTRAIL_FORMATTER_PASSWORD: (required) your TestRail password (not recommended) or API key (recommended)
* TESTRAIL_FORMATTER_DISABLED: (optional) set to 1 to disable the formatter

### Via `RSpec.configure`

```ruby
RSpec.configure do |config|
  config.testrail_formatter_options[:project_id] = ... # (required) the id of the TestRail project
  config.testrail_formatter_options[:run_name]   = ... # (required) the name of the run to target
  config.testrail_formatter_options[:url]        = ... # (required) the URL to target (`"https://your-user.testrail.com"``)
  config.testrail_formatter_options[:user]       = ... # (required) your TestRail user
  config.testrail_formatter_options[:password]   = ... # (required) your TestRail password (not recommended) or API key (recommended)
  config.testrail_formatter_options[:disabled]   = ... # (optional) set to true to disable the formatter
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/manastech/testrail_rspec_formatter.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

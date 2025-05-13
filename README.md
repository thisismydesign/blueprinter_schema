# BlueprinterSchema

### Create JSON Schema from Blueprinter Serializers and ActiveRecord Models.

## Installation

Add to your application's Gemfile:

```rb
gem "blueprinter_schema"
```

## Usage

With the folloing Model and Serializer:
```rb
class User < ApplicationRecord
  # ...
end

class UserSerializer < Blueprinter::Base
  identifier :id

  fields :name, :email, :created_at
end
```

Generate JSON Schema:
```rb
BlueprinterSchema.generate(UserSerializer, User)
```

```rb
{
  "type" => "object",
  "title" => "TestUser",
  "properties" => {
    "id" => {
      "type" => "integer"
    },
    "created_at" => {
      "type" => "string", "format" => "date-time"
    },
    "email" => {
      "type" => "string"
    },
    "name" => {
      "type" => ["string", "null"]
    }
  },
  "required" => ["id", "created_at", "email", "name"],
  "additionalProperties" => false
}
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/thisismydesign/blueprinter_schema.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

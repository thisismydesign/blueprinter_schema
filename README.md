# BlueprinterSchema

#### Create JSON Schemas from [Blueprinter](https://github.com/procore-oss/blueprinter) Serializers.

## Installation

Add to your application's Gemfile:

```rb
gem "blueprinter_schema"
```

## Usage

```rb
class UserSerializer < Blueprinter::Base
  field :first_name, type: [:string, :null]
  field :last_name, type: [:string, :null]
  field :full_name, type: [:string, :null], description: "The concatendated first and last name."
  field :email, type: :string, format: :email
end

BlueprinterSchema.generate(serializer: UserSerializer)
```

```rb
{
  "type" => "object",
  "properties" => {
    "first_name" => {
      "type" => ["string", "null"]
    },
    "last_name" => {
      "type" => ["string", "null"]
    },
    "full_name" => {
      "type" => ["string", "null"],
      "description" => "The concatendated first and last name."
    },
    "email" => {
      "type" => "string",
      "format" => "email"
    }
  },
  "required" => ["first_name", "last_name", "full_name", "email"],
  "additionalProperties" => false
}
```

### Pass an ActiveRecord Model to automatically infer types from DB fields:

```rb
class UserSerializer < Blueprinter::Base
  field :first_name
  field :last_name
  field :email
end

class User < ApplicationRecord
end

BlueprinterSchema.generate(serializer: UserSerializer, model: User)
```

```rb
{
  "type" => "object",
  "title" => "User",
  "properties" => {
    "first_name" => {
      "type" => ["string", "null"]
    },
    "last_name" => {
      "type" => ["string", "null"]
    },
    "email" => {
      "type" => "string"
    }
  },
  "required" => ["first_name", "last_name", "email"],
  "additionalProperties" => false
}
```

### Use associations:

```rb
class UserSerializer < Blueprinter::Base
  field :email, type: :string

  association :addresses, blueprint: AddressSerializer, collection: true
  association :profile, blueprint: ProfileSerializer
end

class AddressSerializer < Blueprinter::Base
  field :address, type: :string
end

class ProfileSerializer < Blueprinter::Base
  field :public, type: :boolean
end

BlueprinterSchema.generate(serializer: UserSerializer)
```

```rb
{
  "type" => "object",
  "properties" => {
    "email" => {
      "type" => "string"
    },
    "addresses" => {
      "type" => "array",
      "items" => {
        "type" => "object",
        "properties" => {
          "address" => {
            "type" => "string"
          }
        },
        "required" => ["address"],
        "additionalProperties" => false
      }
    },
    "profile" => {
      "type" => "object",
      "properties" => {
        "public" => {
          "type" => "boolean"
        }
      },
      "required" => ["public"],
      "additionalProperties" => false
    }
  },
  "required" => ["email", "addresses", "profile"],
  "additionalProperties" => false
}
```

### Options and defaults

```rb
BlueprinterSchema.generate(
  serializer:,
  model: nil,
  include_conditional_fields: true, # Whether or not to include conditional fields from the serializer
  fallback_type: {}, # Type when no DB column or type definition is found. E.g. { 'type' => 'object' }
  view: :default # The blueprint view to use
)
```

## Development

Devcontainer / Codespaces / Native

```sh
bin/setup
```

Docker

```sh
docker compose up -d
docker compose exec ruby bin/setup
```

Then, run `bundle exec rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/thisismydesign/blueprinter_schema.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

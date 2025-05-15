# frozen_string_literal: true

RSpec.describe BlueprinterSchema do
  it 'has a version number' do
    expect(BlueprinterSchema::VERSION).not_to be_nil
  end

  describe '.generate' do
    subject(:generate) { described_class.generate(serializer: user_serializer, model: user_model) }

    let(:address_serializer) do
      Class.new(Blueprinter::Base) do
        identifier :id
        field :address
      end
    end

    let(:user_serializer) do
      address_serializer_local = address_serializer

      Class.new(Blueprinter::Base) do
        identifier :id

        fields :first_name, :last_name, :email, :created_at
        field :full_name, description: 'The concatendated first and last name of the user', type: %w[string null]

        association :addresses, blueprint: address_serializer_local
      end
    end

    let(:user_model) do
      Class.new(ActiveRecord::Base) do
        # Needed to move the Address model inside the User model as a method to make it available for mocking
        # rubocop:disable Metrics/MethodLength
        def self.address_model = Class.new(ActiveRecord::Base) do
          def self.name
            'Address'
          end

          def self.columns_hash
            {
              'id' => Struct.new(:type, :null).new(:integer, false),
              'address' => Struct.new(:type, :null).new(:string, false)
            }
          end
        end
        # rubocop:enable Metrics/MethodLength

        def self.name
          'User'
        end

        def self.columns_hash
          {
            'id' => Struct.new(:type, :null).new(:integer, false),
            'first_name' => Struct.new(:type, :null).new(:string, true),
            'last_name' => Struct.new(:type, :null).new(:string, true),
            'email' => Struct.new(:type, :null).new(:string, false),
            'created_at' => Struct.new(:type, :null).new(:datetime, false)
          }
        end

        def self.reflect_on_association(name)
          return unless name == :addresses

          Struct.new(:collection?, :klass).new(true, address_model)
        end
      end
    end

    # rubocop:disable RSpec/ExampleLength
    it 'generates a schema with the correct structure' do
      expect(generate).to match(
        hash_including(
          {
            'type' => 'object',
            'title' => 'User',
            'properties' => {
              'id' => {
                'type' => 'integer'
              },
              'created_at' => {
                'type' => 'string', 'format' => 'date-time'
              },
              'email' => {
                'type' => 'string'
              },
              'full_name' => {
                'type' => %w[string null],
                'description' => 'The concatendated first and last name of the user'
              },
              'first_name' => {
                'type' => %w[string null]
              },
              'last_name' => {
                'type' => %w[string null]
              },
              'addresses' => {
                'type' => 'array',
                'items' => {
                  'type' => 'object',
                  'title' => 'Address',
                  'properties' => {
                    'id' => {
                      'type' => 'integer'
                    }, 'address' => {
                      'type' => 'string'
                    }
                  },
                  'required' => %w[id address],
                  'additionalProperties' => false
                }
              }
            },
            'required' => match_array(%w[id created_at email full_name first_name last_name]),
            'additionalProperties' => false
          }
        )
      )
    end
    # rubocop:enable RSpec/ExampleLength
  end
end

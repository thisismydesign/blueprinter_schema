# frozen_string_literal: true

RSpec.describe BlueprinterSchema do
  it 'has a version number' do
    expect(BlueprinterSchema::VERSION).not_to be_nil
  end

  describe '.generate' do
    subject(:generate) { described_class.generate(user_serializer, user_model) }

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

        field :name, description: 'The name of the user'
        fields :email, :created_at

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
            'name' => Struct.new(:type, :null).new(:string, true),
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
      expect(generate).to eq(
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
            'name' => {
              'type' => %w[string null],
              'description' => 'The name of the user'
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
          'required' => %w[id created_at email name],
          'additionalProperties' => false
        }
      )
    end
    # rubocop:enable RSpec/ExampleLength
  end
end

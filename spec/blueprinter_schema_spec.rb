# frozen_string_literal: true

RSpec.describe BlueprinterSchema do
  it 'has a version number' do
    expect(BlueprinterSchema::VERSION).not_to be_nil
  end

  describe '.generate' do
    subject(:generate) { described_class.generate(serializer: user_serializer) }

    let(:user_serializer) do
      Class.new(Blueprinter::Base) do
        field :email
      end
    end

    it 'generates json schema' do
      expect(generate).to match(
        hash_including(
          'type' => 'object',
          'properties' => {
            'email' => {}
          },
          'required' => %w[email],
          'additionalProperties' => false
        )
      )
    end

    context 'with custom field type' do
      let(:user_serializer) do
        Class.new(Blueprinter::Base) do
          field :email, type: :string
        end
      end

      it 'generates json schema with correct type' do
        expect(generate).to match(
          hash_including(
            'type' => 'object',
            'properties' => {
              'email' => { 'type' => :string }
            },
            'required' => %w[email],
            'additionalProperties' => false
          )
        )
      end
    end

    context 'with an invalid custom field type' do
      let(:user_serializer) do
        Class.new(Blueprinter::Base) do
          field :email, type: 'invalid'
        end
      end

      it 'raises an error' do
        expect { generate }.to raise_error(BlueprinterSchema::InvalidJsonSchemaType)
      end
    end

    context 'with custom field format' do
      let(:user_serializer) do
        Class.new(Blueprinter::Base) do
          field :email, type: 'string', format: 'email'
        end
      end

      it 'generates json schema with correct format' do
        expect(generate).to match(
          hash_including(
            'type' => 'object',
            'properties' => {
              'email' => { 'type' => 'string', 'format' => 'email' }
            },
            'required' => %w[email],
            'additionalProperties' => false
          )
        )
      end
    end

    context 'when association is provided' do
      subject(:generate) { described_class.generate(serializer: user_serializer) }

      let(:address_serializer) do
        Class.new(Blueprinter::Base) do
          identifier :id
          field :address, type: %w[string null]
        end
      end

      let(:user_serializer) do
        address_serializer_local = address_serializer

        Class.new(Blueprinter::Base) do
          identifier :id

          association :addresses, blueprint: address_serializer_local, collection: true
        end
      end

      it 'generates a schema with the correct structure' do
        expect(generate).to match(
          hash_including(
            'type' => 'object',
            'properties' => {
              'id' => {},
              'addresses' => {
                'type' => 'array',
                'items' => {
                  'type' => 'object',
                  'properties' => { 'id' => {}, 'address' => { 'type' => %w[string null] } },
                  'required' => %w[id address],
                  'additionalProperties' => false
                }
              }
            },
            'required' => %w[id],
            'additionalProperties' => false
          )
        )
      end
    end

    context 'when nested association specifies a view' do
      let(:customer_serializer) do
        Class.new(Blueprinter::Base) do
          identifier :id
          fields :first_name, :last_name, :email
        end
      end

      let(:order_serializer) do
        customer_serializer_local = customer_serializer

        Class.new(Blueprinter::Base) do
          identifier :id
          fields :reference, :currency
          association :customer, blueprint: customer_serializer_local

          view :for_booking do
          end

          view :for_event do
            fields :total, :balance
            association :customer, blueprint: customer_serializer_local
          end
        end
      end

      let(:booking_serializer) do
        order_serializer_local = order_serializer

        Class.new(Blueprinter::Base) do
          identifier :id
          fields :reference, :amount

          view :for_event do
            association :order, blueprint: order_serializer_local, view: :for_booking
          end
        end
      end

      subject(:generate) { described_class.generate(serializer: booking_serializer, view: :for_event) }

      it 'resolves the view on the nested serializer' do
        expect(generate).to match(
          hash_including(
            'type' => 'object',
            'properties' => hash_including(
              'id' => {},
              'reference' => {},
              'amount' => {},
              'order' => hash_including(
                'type' => 'object',
                'properties' => hash_including(
                  'id' => {},
                  'reference' => {},
                  'currency' => {},
                  'customer' => hash_including(
                    'type' => 'object',
                    'properties' => hash_including(
                      'id' => {},
                      'first_name' => {},
                      'last_name' => {},
                      'email' => {}
                    )
                  )
                )
              )
            )
          )
        )
      end
    end

    context 'when nested serializer does not define a view' do
      let(:address_serializer) do
        Class.new(Blueprinter::Base) do
          identifier :id
          field :street

          view :extended do
            field :city
          end
        end
      end

      let(:user_serializer) do
        address_serializer_local = address_serializer

        Class.new(Blueprinter::Base) do
          identifier :id
          field :email

          view :extended do
            field :name
            association :address, blueprint: address_serializer_local
          end
        end
      end

      subject(:generate) { described_class.generate(serializer: user_serializer, view: :extended) }

      it 'uses the default view for the nested serializer' do
        address_schema = generate.dig('properties', 'address', 'properties')

        expect(address_schema.keys).to match_array(%w[id street])
        expect(address_schema).not_to have_key('city')
      end
    end

    context 'when model is provided' do
      subject(:generate) { described_class.generate(serializer: user_serializer, model: user_model) }

      let(:address_serializer) do
        Class.new(Blueprinter::Base) do
          identifier :id
          field :address, type: %w[string null]
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
                      },
                      'address' => {
                        'type' => %w[string null]
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
    end
  end
end

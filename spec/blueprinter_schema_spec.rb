# frozen_string_literal: true

RSpec.describe BlueprinterSchema do
  it 'has a version number' do
    expect(BlueprinterSchema::VERSION).not_to be_nil
  end

  describe '.generate' do
    subject(:generate) { described_class.generate(test_user_serializer, test_user_model) }

    let(:test_user_serializer) do
      Class.new(Blueprinter::Base) do
        identifier :id
        fields :name, :email, :created_at
      end
    end

    let(:test_user_model) do
      Class.new(ActiveRecord::Base) do
        def self.name
          'TestUser'
        end

        def self.columns_hash
          {
            'id' => Struct.new(:type, :null).new(:integer, false),
            'name' => Struct.new(:type, :null).new(:string, true),
            'email' => Struct.new(:type, :null).new(:string, false),
            'created_at' => Struct.new(:type, :null).new(:datetime, false)
          }
        end
      end
    end

    # rubocop:disable RSpec/ExampleLength
    it 'generates a schema with the correct structure' do
      expect(generate).to eq(
        'type' => 'object',
        'title' => 'TestUser',
        'properties' => { 'id' => { 'type' => 'integer' },
                          'created_at' => { 'type' => 'string', 'format' => 'date-time' },
                          'email' => { 'type' => 'string' },
                          'name' => { 'type' => %w[string null] } },
        'required' => %w[id created_at email name],
        'additionalProperties' => false
      )
    end
    # rubocop:enable RSpec/ExampleLength
  end
end

# frozen_string_literal: true

RSpec.describe BlueprinterSchema::ModelAttributes do
  subject(:attributes) { described_class.new(model) }

  context 'with an ActiveRecord model' do
    let(:model) do
      Class.new do
        def self.columns_hash
          {
            'name' => Struct.new(:type, :null).new(:string, false),
            'bio' => Struct.new(:type, :null).new(:text, true)
          }
        end
      end
    end

    it 'infers the type from the column' do
      expect(attributes.type('name')).to eq(:string)
    end

    it 'infers a non-null column as non-null' do
      expect(attributes.nullable?('name')).to be(false)
    end

    it 'infers a nullable column as nullable' do
      expect(attributes.nullable?('bio')).to be(true)
    end

    context 'when the column is missing' do
      it 'returns no type' do
        expect(attributes.type('unknown')).to be_nil
      end

      it 'is non-null' do
        expect(attributes.nullable?('unknown')).to be(false)
      end
    end
  end

  context 'with an ActiveModel model that includes validations' do
    let(:model) do
      Class.new do
        include ActiveModel::Model
        include ActiveModel::Attributes

        attribute :min_units, :integer
        attribute :max_units, :integer

        validates :min_units, presence: true
      end
    end

    it 'infers the type from the attribute' do
      expect(attributes.type('min_units')).to eq(:integer)
    end

    it 'is non-null when a presence validation exists' do
      expect(attributes.nullable?('min_units')).to be(false)
    end

    it 'is nullable when no presence validation exists' do
      expect(attributes.nullable?('max_units')).to be(true)
    end
  end

  context 'with an ActiveModel model without validations' do
    let(:model) do
      Class.new do
        include ActiveModel::Attributes

        attribute :min_units, :integer
      end
    end

    it 'infers the type from the attribute' do
      expect(attributes.type('min_units')).to eq(:integer)
    end

    it 'assumes the attribute is nullable' do
      expect(attributes.nullable?('min_units')).to be(true)
    end
  end

  context 'with a model that is neither ActiveRecord nor ActiveModel' do
    let(:model) { Class.new }

    it 'returns no type' do
      expect(attributes.type('anything')).to be_nil
    end

    it 'is non-null' do
      expect(attributes.nullable?('anything')).to be(false)
    end
  end
end

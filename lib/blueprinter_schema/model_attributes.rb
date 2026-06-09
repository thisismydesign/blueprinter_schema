# frozen_string_literal: true

module BlueprinterSchema
  # Resolves an attribute's type and nullability from a model.
  #
  # ActiveRecord models (responding to +columns_hash+) infer both the type and
  # nullability from the column. ActiveModel objects (responding to
  # +type_for_attribute+) infer the type from the attribute; nullability is
  # inferred from presence validations when available, otherwise assumed nullable.
  class ModelAttributes
    def initialize(model)
      @model = model
    end

    def type(name)
      if active_record?
        @model.columns_hash[name]&.type
      elsif active_model?
        @model.type_for_attribute(name)&.type
      end
    end

    def nullable?(name)
      if active_record?
        column = @model.columns_hash[name]
        column ? column.null : false
      elsif active_model?
        active_model_nullable?(name)
      else
        false
      end
    end

    private

    def active_record?
      @model.respond_to?(:columns_hash)
    end

    def active_model?
      @model.respond_to?(:type_for_attribute)
    end

    def active_model_nullable?(name)
      return true unless @model.respond_to?(:validators_on)

      !presence_validated?(name)
    end

    def presence_validated?(name)
      @model.validators_on(name).any? { |validator| validator.kind == :presence }
    end
  end
end

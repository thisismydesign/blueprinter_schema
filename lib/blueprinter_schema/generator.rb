# frozen_string_literal: true

module BlueprinterSchema
  class InvalidJsonSchemaType < StandardError; end

  # rubocop:disable Metrics/ClassLength
  class Generator
    def initialize(serializer:, model:, skip_conditional_fields:, fallback_definition:, view:, type:) # rubocop:disable Metrics/ParameterLists
      @serializer = serializer
      @model = model
      @skip_conditional_fields = skip_conditional_fields
      @fallback_definition = fallback_definition
      @view = view
      @type = type
    end

    def generate
      schema = {
        'type' => @type,
        'properties' => build_properties,
        'required' => build_required_fields,
        'additionalProperties' => false
      }

      schema['title'] = @model.name if @model

      schema
    end

    private

    def fields
      @fields ||= @serializer.reflections[@view].fields
    end

    def associations
      @associations ||= @serializer.reflections[@view].associations
    end

    def build_properties
      properties = {}

      fields.each_value do |field|
        next if skip_field?(field)

        properties[field.display_name.to_s] = field_to_json_schema(field)
      end

      associations.each_value do |association|
        properties[association.display_name.to_s] = association_to_json_schema(association)
      end

      properties
    end

    def skip_field?(field)
      @skip_conditional_fields && (field.options[:if] || field.options[:unless])
    end

    def build_required_fields
      (required_field_names + required_association_names).map(&:to_s)
    end

    def required_field_names
      fields
        .reject { |_, field| field.options[:exclude_if_nil] }
        .reject { |_, field| skip_field?(field) }
        .keys
    end

    def required_association_names
      associations
        .reject { |_, association| association.options[:exclude_if_nil] }
        .reject { |_, association| skip_field?(association) }
        .keys
    end

    def field_to_json_schema(field)
      type_definition = @fallback_definition.dup

      if field.options[:type]
        type_definition['type'] = ensure_valid_json_schema_types!(field)
      elsif @model
        type_definition = model_attribute_to_json_schema(field.name.to_s)
      end

      merge_field_options(type_definition, field.options)
    end

    def model_attribute_to_json_schema(name)
      type_to_json_schema(model_attributes.type(name), model_attributes.nullable?(name))
    end

    def model_attributes
      @model_attributes ||= ModelAttributes.new(@model)
    end

    def merge_field_options(type_definition, options)
      type_definition['enum'] = options[:enum] if options[:enum]
      type_definition['items'] = options[:items].deep_stringify_keys if options[:items]
      type_definition['format'] = options[:format] if options[:format]
      type_definition['description'] = options[:description] if options[:description]
      type_definition
    end

    def ensure_valid_json_schema_types!(field)
      types = [field.options[:type]].flatten.map(&:to_s)

      return field.options[:type] if types.all? do |type|
        %w[string integer number boolean object array null].include?(type)
      end

      raise BlueprinterSchema::InvalidJsonSchemaType, "Invalid type: #{field.options[:type]}"
    end

    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/CyclomaticComplexity
    def type_to_json_schema(type, null)
      case type
      when :string, :text
        build_json_schema_type('string', null)
      when :integer
        build_json_schema_type('integer', null)
      when :float, :decimal
        build_json_schema_type('number', null)
      when :boolean
        build_json_schema_type('boolean', null)
      when :date
        build_json_schema_type('string', null, 'date')
      when :datetime, :timestamp
        build_json_schema_type('string', null, 'date-time')
      when :uuid
        build_json_schema_type('string', null, 'uuid')
      else
        @fallback_definition.dup
      end
    end
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/CyclomaticComplexity

    def build_json_schema_type(json_schema_type, nullable, format = nil)
      type = { 'type' => nullable ? [json_schema_type, 'null'] : json_schema_type }
      type['format'] = format if format
      type
    end

    def association_to_json_schema(association)
      blueprint_class = association.options[:blueprint]

      return { 'type' => 'object' } unless blueprint_class

      ar_association = @model.try(:reflect_on_association, association.name)
      is_collection = ar_association ? ar_association.collection? : association.options[:collection]

      view = association.options[:view] || :default
      type = association.options[:optional] ? %w[object null] : 'object'
      associated_schema = recursive_generate(blueprint_class, ar_association&.klass, view, type:)

      is_collection ? { 'type' => 'array', 'items' => associated_schema } : associated_schema
    end

    def recursive_generate(serializer, model, view, type:)
      BlueprinterSchema.generate(
        serializer:,
        model:,
        skip_conditional_fields: @skip_conditional_fields,
        fallback_definition: @fallback_definition,
        view:,
        type:
      )
    end
  end
  # rubocop:enable Metrics/ClassLength
end

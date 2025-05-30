# frozen_string_literal: true

module BlueprinterSchema
  class InvalidJsonSchemaType < StandardError; end

  # rubocop:disable Metrics/ClassLength
  class Generator
    def initialize(serializer:, model:, skip_conditional_fields:, fallback_definition:, view:)
      @serializer = serializer
      @model = model
      @skip_conditional_fields = skip_conditional_fields
      @fallback_definition = fallback_definition
      @view = view
    end

    def generate
      schema = {
        'type' => 'object',
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
      fields
        .reject { |_, field| field.options[:exclude_if_nil] }
        .reject { |_, field| skip_field?(field) }
        .keys.map(&:to_s)
    end

    # rubocop:disable Metrics/AbcSize
    def field_to_json_schema(field)
      type_definition = @fallback_definition.dup

      if field.options[:type]
        type_definition['type'] = ensure_valid_json_schema_types!(field)
      elsif @model
        column = @model.columns_hash[field.name.to_s]
        type_definition = ar_column_to_json_schema(column)
      end

      type_definition['format'] = field.options[:format] if field.options[:format]
      type_definition['description'] = field.options[:description] if field.options[:description]
      type_definition
    end
    # rubocop:enable Metrics/AbcSize

    def ensure_valid_json_schema_types!(field)
      types = [field.options[:type]].flatten.map(&:to_s)

      return field.options[:type] if types.all? do |type|
        %w[string integer number boolean object array null].include?(type)
      end

      raise BlueprinterSchema::InvalidJsonSchemaType, "Invalid type: #{field.options[:type]}"
    end

    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/CyclomaticComplexity
    def ar_column_to_json_schema(column)
      case column&.type
      when :string, :text
        build_json_schema_type('string', column.null)
      when :integer
        build_json_schema_type('integer', column.null)
      when :float, :decimal
        build_json_schema_type('number', column.null)
      when :boolean
        build_json_schema_type('boolean', column.null)
      when :date
        build_json_schema_type('string', column.null, 'date')
      when :datetime, :timestamp
        build_json_schema_type('string', column.null, 'date-time')
      when :uuid
        build_json_schema_type('string', column.null, 'uuid')
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

      ar_association = @model&.reflect_on_association(association.name)
      is_collection = ar_association ? ar_association.collection? : association.options[:collection]

      associated_schema = recursive_generate(blueprint_class, ar_association&.klass)

      is_collection ? { 'type' => 'array', 'items' => associated_schema } : associated_schema
    end

    def recursive_generate(serializer, model)
      BlueprinterSchema.generate(
        serializer:,
        model:,
        skip_conditional_fields: @skip_conditional_fields,
        fallback_definition: @fallback_definition,
        view: @view
      )
    end
  end
  # rubocop:enable Metrics/ClassLength
end

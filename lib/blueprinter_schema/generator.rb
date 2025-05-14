# frozen_string_literal: true

module BlueprinterSchema
  class Generator
    def initialize(serializer, model, options = { include_conditional_fields: true, fallback_type: {} })
      @serializer = serializer
      @model = model
      @options = options
    end

    def generate
      {
        'type' => 'object',
        'title' => @model.name,
        'properties' => build_properties,
        'required' => build_required_fields,
        'additionalProperties' => false
      }
    end

    private

    def fields
      @fields ||= @serializer.reflections[:default].fields
    end

    def associations
      @associations ||= @serializer.reflections[:default].associations
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
      !@options[:include_conditional_fields] &&
        (field.options[:if] || field.options[:unless] || field.options[:exclude_if_nil])
    end

    def build_required_fields
      fields.reject { |_, field| skip_field?(field) }.keys.map(&:to_s)
    end

    def field_to_json_schema(field)
      column = @model.columns_hash[field.name.to_s]

      ar_column_to_json_schema(column) || @options[:fallback_type]
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

      ar_association = @model.reflect_on_association(association.name)
      is_collection = ar_association.collection?
      association_model = ar_association.klass

      associated_schema = BlueprinterSchema.generate(blueprint_class, association_model)

      is_collection ? { 'type' => 'array', 'items' => associated_schema } : associated_schema
    end
  end
end

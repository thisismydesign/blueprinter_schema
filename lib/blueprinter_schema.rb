# frozen_string_literal: true

require_relative 'blueprinter_schema/version'

module BlueprinterSchema
  class << self
    def generate(serializer, model, options = { include_conditional_fields: true, fallback_type: {} })
      views = serializer.reflections
      fields = views[:default].fields
      associations = views[:default].associations

      {
        'type' => 'object',
        'title' => model.name,
        'properties' => build_properties(fields, associations, model, options),
        'required' => build_required_fields(fields),
        'additionalProperties' => false
      }
    end

    private

    def build_properties(fields, associations, model, options)
      properties = {}

      fields.each_value do |field|
        next if skip_field?(field, options)

        properties[field.display_name.to_s] = field_to_json_schema(field, model, options)
      end

      associations.each_value do |association|
        properties[association.display_name.to_s] = association_to_json_schema(association, model)
      end

      properties
    end

    def skip_field?(field, options)
      !options[:include_conditional_fields] && (field.options[:if] || field.options[:unless])
    end

    def build_required_fields(fields)
      fields.keys.map(&:to_s)
    end

    def field_to_json_schema(field, model, options)
      column = model.columns_hash[field.name.to_s]

      ar_column_to_json_schema(column) || options[:fallback_type]
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

    def association_to_json_schema(association, model)
      blueprint_class = association.options[:blueprint]

      return { 'type' => 'object' } unless blueprint_class

      ar_association = model.reflect_on_association(association.name)
      is_collection = ar_association.collection?
      association_model = ar_association.klass

      associated_schema = generate(blueprint_class, association_model)

      is_collection ? { 'type' => 'array', 'items' => associated_schema } : associated_schema
    end
  end
end

# frozen_string_literal: true

require_relative 'blueprinter_schema/version'
require_relative 'blueprinter_schema/generator'

module BlueprinterSchema
  def self.generate( # rubocop:disable Metrics/ParameterLists
    serializer:,
    model: nil,
    skip_conditional_fields: false,
    fallback_definition: {},
    view: :default,
    type: 'object'
  )
    Generator.new(serializer:, model:, skip_conditional_fields:, fallback_definition:, view:, type:).generate
  end
end

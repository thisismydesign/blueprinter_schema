# frozen_string_literal: true

require_relative 'blueprinter_schema/version'
require_relative 'blueprinter_schema/generator'

module BlueprinterSchema
  def self.generate(
    serializer:,
    model: nil,
    skip_conditional_fields: false,
    fallback_definition: {},
    view: :default
  )
    Generator.new(serializer:, model:, skip_conditional_fields:, fallback_definition:, view:).generate
  end
end

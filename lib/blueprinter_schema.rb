# frozen_string_literal: true

require_relative 'blueprinter_schema/version'
require_relative 'blueprinter_schema/generator'

module BlueprinterSchema
  def self.generate(
    serializer:,
    model: nil,
    include_conditional_fields: true,
    fallback_definition: {},
    view: :default
  )
    Generator.new(serializer:, model:, include_conditional_fields:, fallback_definition:, view:).generate
  end
end

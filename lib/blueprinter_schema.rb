# frozen_string_literal: true

require_relative 'blueprinter_schema/version'
require_relative 'blueprinter_schema/generator'

module BlueprinterSchema
  def self.generate(
    serializer:,
    model:,
    include_conditional_fields: true,
    fallback_type: {},
    view: :default
  )
    Generator.new(serializer:, model:, include_conditional_fields:, fallback_type:, view:).generate
  end
end

# frozen_string_literal: true

RSpec.describe BlueprinterSchema do
  it 'has a version number' do
    expect(BlueprinterSchema::VERSION).not_to be_nil
  end
end

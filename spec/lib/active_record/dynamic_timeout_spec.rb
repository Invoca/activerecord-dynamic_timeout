# frozen_string_literal: true

require "active_record/dynamic_timeout"

RSpec.describe ActiveRecord::DynamicTimeout do
  it "has a version number" do
    expect(ActiveRecord::DynamicTimeout::VERSION).not_to be nil
  end
end

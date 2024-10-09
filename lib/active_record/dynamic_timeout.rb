# frozen_string_literal: true

require "active_record"
require "active_support"

require_relative "dynamic_timeout/version"
require_relative "dynamic_timeout/initializer"

module ActiveRecord
  module DynamicTimeout
  end
end

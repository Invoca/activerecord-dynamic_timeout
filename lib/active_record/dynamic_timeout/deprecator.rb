# frozen_string_literal: true

module ActiveRecord::DynamicTimeout
  # @return [ActiveSupport::Deprecation]
  def self.deprecator
    @deprecator ||= ActiveSupport::Deprecation.new("1.0", "ActiveRecord::DynamicTimeout")
  end
end

# frozen_string_literal: true

require_relative "../dynamic_timeout"
require_relative "initializer"

module ActiveRecord::DynamicTimeout
  class Railtie < Rails::Railtie
    initializer "active_record-dynamic_timeout.initialize", after: "active_record.initialize_database" do |app|
      ActiveSupport.on_load :active_record do
        ActiveRecord::DynamicTimeout::Initializer.initialize!
      end
    end
  end
end

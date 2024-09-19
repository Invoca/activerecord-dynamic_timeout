# frozen_string_literal: true

require_relative "../connection_manager"

module ActiveRecord::DynamicTimeout
  module AdapterExtension
    def configure_connection
      super
      if active_record_dynamic_timeout
        ActiveRecord::DynamicTimeout::ConnectionManager.timeout_manager.set_timeout(self, active_record_dynamic_timeout)
      end
    end
  end

  module Rails7_1_AdapterExtension
    def with_raw_connection(*args, **kwargs, &block)
      super do |raw_connection|
        set_timeout(ActiveRecord::DynamicTimeout.current_timeout, raw_connection)
        yield raw_connection
      ensure
        if ActiveRecord::DynamicTimeout::ConnectionManager.timeout_manager.client_side?
          ActiveRecord::DynamicTimeout::ConnectionManager.timeout_manager.reset_timeout(self)
        end
      end
    end
  end
end

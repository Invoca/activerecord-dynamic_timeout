# frozen_string_literal: true

module ActiveRecord::DynamicTimeout
  module SqliteAdapterExtension
    def set_connection_timeout(raw_connection, timeout)
      if timeout
        raw_connection.busy_timeout(timeout)
      else
        raw_connection.busy_timeout(0)
      end
    end

    def reset_connection_timeout(raw_connection)
      timeout = @config[:timeout]
      set_connection_timeout(raw_connection, self.class.type_cast_config_to_integer(timeout))
    end

    def timeout_set_client_side?
      false
    end

    def supports_dynamic_timeouts?
      true
    end
  end
end

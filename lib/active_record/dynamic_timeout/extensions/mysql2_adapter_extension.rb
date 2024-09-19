module ActiveRecord::DynamicTimeout
  module Mysql2AdapterExtension
    def set_connection_timeout(raw_connection, timeout)
      set_timeouts_on_connection(raw_connection, read_timeout: timeout, write_timeout: timeout)
    end

    def reset_connection_timeout(raw_connection)
      read_timeout = @config[:read_timeout]
      write_timeout = @config[:write_timeout]
      set_timeouts_on_connection(raw_connection, read_timeout:, write_timeout:)
    end

    def set_timeouts_on_connection(raw_connection, read_timeout:, write_timeout:)
      raw_connection.instance_variable_set(:@read_timeout, read_timeout)
      raw_connection.instance_variable_set(:@write_timeout, write_timeout)
    end

    def timeout_set_client_side?
      true
    end

    def supports_dynamic_timeouts?
      true
    end
  end
end

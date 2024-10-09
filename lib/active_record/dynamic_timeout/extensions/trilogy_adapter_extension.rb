module ActiveRecord::DynamicTimeout
  module TrilogyAdapterExtension
    def set_connection_timeout(raw_connection, timeout_seconds)
      timeout = timeout_seconds.ceil.to_i # Round floats up to the nearest integer
      set_timeouts_on_connection(raw_connection, read_timeout: timeout, write_timeout: timeout)
    end

    def reset_connection_timeout(raw_connection)
      read_timeout = @config[:read_timeout]
      write_timeout = @config[:write_timeout]
      set_timeouts_on_connection(raw_connection, read_timeout:, write_timeout:)
    end

    def timeout_set_client_side?
      true
    end

    def supports_dynamic_timeouts?
      true
    end

    private

    def set_timeouts_on_connection(raw_connection, read_timeout:, write_timeout:)
      raw_connection.read_timeout = read_timeout
      raw_connection.write_timeout = write_timeout
    end
  end
end

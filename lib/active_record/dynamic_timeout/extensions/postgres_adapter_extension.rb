module ActiveRecord::DynamicTimeout
  module PostgresAdapterExtension
    def set_connection_timeout(raw_connection, timeout_seconds)
      if set_to_default_timeout?(timeout_seconds)
        raw_connection.query("SET SESSION statement_timeout TO DEFAULT")
      else
        timeout = (timeout_seconds * 1000).to_i
        raw_connection.query("SET SESSION statement_timeout TO #{quote(timeout)}")
      end
    end

    def reset_connection_timeout(raw_connection)
      timeout = default_statement_timeout
      if set_to_default_timeout?(timeout)
        raw_connection.query("SET SESSION statement_timeout TO DEFAULT")
      else
        raw_connection.query("SET SESSION statement_timeout TO #{quote(timeout)}")
      end
    end

    def timeout_set_client_side?
      false
    end

    def supports_dynamic_timeouts?
      true
    end

    private

    def set_to_default_timeout?(timeout)
      timeout.nil? || timeout == ":default" || timeout == :default
    end

    def default_statement_timeout
      unless defined?(@default_statement_timeout)
        @default_statement_timeout = @config.fetch(:variables, {}).stringify_keys["statement_timeout"]
      end
      @default_statement_timeout
    end
  end
end

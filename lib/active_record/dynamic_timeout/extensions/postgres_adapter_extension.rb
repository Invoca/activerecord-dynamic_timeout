module ActiveRecord::DynamicTimeout
  module PostgresAdapterExtension
    def set_connection_timeout(raw_connection, timeout)
      if timeout.nil? || timeout == ":default" || timeout == :default
        raw_connection.query("SET SESSION statement_timeout TO DEFAULT")
      else
        raw_connection.query("SET SESSION statement_timeout TO #{timeout}")
      end
    end

    def reset_connection_timeout(raw_connection)
      set_connection_timeout(raw_connection, default_statement_timeout)
    end

    def default_statement_timeout
      unless defined?(@default_statement_timeout)
        @default_statement_timeout = @config.fetch(:variables, {}).stringify_keys["statement_timeout"]
      end
      @default_statement_timeout
    end

    def timeout_set_client_side?
      false
    end

    def supports_dynamic_timeouts?
      true
    end
  end
end

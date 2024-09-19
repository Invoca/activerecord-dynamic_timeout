# frozen_string_literal: true

module ActiveRecord::DynamicTimeout
  class PostgresTimeoutManager
    # @param connection [ActiveRecord::ConnectionAdapters::PostgreSQLAdapter]
    # @param timeout [Integer, nil]
    def self.set_timeout(connection, timeout)
      if timeout.nil? || timeout == ":default" || timeout == :default
        connection.execute("SET SESSION statement_timeout TO DEFAULT", "DYNAMIC_TIMEOUT")
      else
        connection.execute("SET SESSION statement_timeout TO #{connection.quote(timeout)}", "DYNAMIC_TIMEOUT")
      end
    end

    # @param connection [ActiveRecord::ConnectionAdapters::PostgreSQLAdapter]
    # @param config [Hash]
    def self.reset_timeout(connection, config)
      timeout = config.fetch(:variables, {}).stringify_keys["statement_timeout"]
      set_timeout(connection, timeout)
    end

    # @return [Boolean]
    def self.client_side?
      false
    end
  end
end

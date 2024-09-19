# frozen_string_literal: true

module ActiveRecord::DynamicTimeout
  class SqliteTimeoutManager
    # @param connection [ActiveRecord::ConnectionAdapters::SQLite3Adapter]
    # @param timeout [Integer, nil]
    def self.set_timeout(connection, timeout)
      raw_connection = connection.raw_connection
      if timeout
        raw_connection.busy_timeout(connection.class.type_cast_config_to_integer(timeout))
      else
        raw_connection.busy_timeout(0)
      end
    end

    # @param connection [ActiveRecord::ConnectionAdapters::SQLite3Adapter]
    # @param config [Hash]
    def self.reset_timeout(connection, config)
      timeout = config[:timeout]
      set_timeout(connection, timeout)
    end

    # @return [Boolean]
    def self.client_side?
      false
    end
  end
end

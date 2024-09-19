# frozen_string_literal: true

module ActiveRecord::DynamicTimeout
  class TrilogyTimeoutManager
    # @param connection [ActiveRecord::ConnectionAdapters::TrilogyAdapter]
    # @param timeout [Integer, nil]
    def self.set_timeout(connection, timeout)
      set_timeouts(connection, read_timeout: timeout, write_timeout: timeout)
    end

    # @param connection [ActiveRecord::ConnectionAdapters::TrilogyAdapter]
    # @param config [Hash]
    def self.reset_timeout(connection, config)
      read_timeout = config[:read_timeout]
      write_timeout = config[:write_timeout]
      set_timeouts(connection, read_timeout:, write_timeout:)
    end

    # @return [Boolean]
    def self.client_side?
      true
    end

    private

    def self.set_timeouts(connection, read_timeout:, write_timeout:)
      connection.raw_connection.read_timeout = read_timeout
      connection.raw_connection.write_timeout = write_timeout
    end
  end
end

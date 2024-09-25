# frozen_string_literal: true

module ActiveRecord::DynamicTimeout
  module SqliteAdapterExtension
    def set_connection_timeout(raw_connection, timeout_seconds)
      if timeout_seconds
        raw_connection.statement_timeout = (timeout_seconds * 1000).to_i
      else
        raw_connection.statement_timeout = 0
      end
    end

    def reset_connection_timeout(raw_connection)
      raw_connection.statement_timeout = 0
    end

    def timeout_set_client_side?
      true
    end

    def supports_dynamic_timeouts?
      SQLite3::VERSION >= "2"
    end
  end
end

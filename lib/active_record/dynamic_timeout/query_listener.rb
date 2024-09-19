# frozen_string_literal: true

require "active_support"
require "active_support/core_ext"
require_relative "connection_manager"
require_relative "../dynamic_timeout"

module ActiveRecord::DynamicTimeout
  class QueryListener
    # Runs before the query
    def start(_name, _id, payload)
      if (connection = payload[:connection]) && !payload[:name]&.starts_with?("DYNAMIC_TIMEOUT")
        ActiveRecord::DynamicTimeout::ConnectionManager.set_timeout(connection, ActiveRecord::DynamicTimeout.current_timeout)
      end
    end

    # Runs after the query
    def finish(_name, _id, payload)
      # Only run this for connections that set the timeout on the client side.
      # Or else this would cause a lot of extra queries to be run.
      if (connection = payload[:connection]) && !payload[:name]&.starts_with?("DYNAMIC_TIMEOUT") && ActiveRecord::DynamicTimeout::ConnectionManager.timeout_manager.client_side?
        ActiveRecord::DynamicTimeout::ConnectionManager.reset_timeout(connection)
      end
    end
  end
end

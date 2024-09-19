# frozen_string_literal: true

require "active_record"
require "active_support"
require_relative "../dynamic_timeout"
require_relative "connection_manager"
require_relative "query_listener"
require_relative "extensions/adapter_extension"
require_relative "timeout_managers/mysql2_timeout_manager"
require_relative "timeout_managers/trilogy_timeout_manager"
require_relative "timeout_managers/sqlite_timeout_manager"
require_relative "timeout_managers/postgres_timeout_manager"

module ActiveRecord::DynamicTimeout
  module Initializer
    class << self
      def initialize!
        register_adapters

        # Used to track per connection whether the timeout has already been set or not.
        unless ActiveRecord::ConnectionAdapters::AbstractAdapter.method_defined?(:active_record_dynamic_timeout)
          ActiveRecord::ConnectionAdapters::AbstractAdapter.attr_accessor :active_record_dynamic_timeout
        end

        # This ensures connections have their timeout set on reconnects.
        ActiveRecord::Base.connection.class.prepend(ActiveRecord::DynamicTimeout::AdapterExtension)

        # Decide which timeout manager to use based on the adapter class (aka Mysql2, Trilogy, Postgres, SQLite3)
        ActiveRecord::DynamicTimeout::ConnectionManager.set_timeout_manager(adapter_class: ActiveRecord::Base.connection.class)

        # Ensure we set the timeout when a connection is checked out of the pool
        ActiveRecord::ConnectionAdapters::AbstractAdapter.set_callback(:checkout, :after, prepend: true) do |connection|
          ActiveRecord::DynamicTimeout::ConnectionManager.set_timeout(connection, ActiveRecord::DynamicTimeout.current_timeout)
        end

        # Ensure we clear the timeout when a connection is checked back into the pool
        ActiveRecord::ConnectionAdapters::AbstractAdapter.set_callback(:checkin, :before, prepend: true) do |connection|
          ActiveRecord::DynamicTimeout::ConnectionManager.reset_timeout(connection)
        end

        # Sets the timeout on the connection before queries are executed.
        ActiveSupport::Notifications.subscribe("sql.active_record", ActiveRecord::DynamicTimeout::QueryListener.new)
      end

      def register_adapters
        ActiveRecord::DynamicTimeout::ConnectionManager.register_adapter("ActiveRecord::ConnectionAdapters::Mysql2Adapter", ActiveRecord::DynamicTimeout::Mysql2TimeoutManager)
        ActiveRecord::DynamicTimeout::ConnectionManager.register_adapter("ActiveRecord::ConnectionAdapters::TrilogyAdapter", ActiveRecord::DynamicTimeout::TrilogyTimeoutManager)
        ActiveRecord::DynamicTimeout::ConnectionManager.register_adapter("ActiveRecord::ConnectionAdapters::SQLite3Adapter", ActiveRecord::DynamicTimeout::SqliteTimeoutManager)
        ActiveRecord::DynamicTimeout::ConnectionManager.register_adapter("ActiveRecord::ConnectionAdapters::PostgreSQLAdapter", ActiveRecord::DynamicTimeout::PostgresTimeoutManager)
      end
    end
  end
end

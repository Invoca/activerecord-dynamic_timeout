# frozen_string_literal: true

require "active_record"
require "active_support"
require_relative "../dynamic_timeout"
require_relative "extensions/adapter_extension"
require_relative "extensions/base_extension"
require_relative "extensions/mysql2_adapter_extension"
require_relative "extensions/trilogy_adapter_extension"
require_relative "extensions/sqlite_adapter_extension"
require_relative "extensions/postgres_adapter_extension"

module ActiveRecord::DynamicTimeout
  module Initializer
    class << self
      def initialize!
        ActiveRecord::Base.include(ActiveRecord::DynamicTimeout::BaseExtension)
        ActiveRecord::Base.connection.class.include(ActiveRecord::DynamicTimeout::AbstractAdapterExtension)

        if ActiveRecord.gem_version < "7.1"
          ActiveRecord::Base.connection.class.prepend(ActiveRecord::DynamicTimeout::TimeoutAdapterExtension_Rails_7_0)
        else
          ActiveRecord::Base.connection.class.prepend(ActiveRecord::DynamicTimeout::TimeoutAdapterExtension)
        end
        register_adapter_extension(ActiveRecord::Base.connection.class)
      end

      def register_adapter_extension(adapter_class)
        extension = case adapter_class.name
                    when "ActiveRecord::ConnectionAdapters::Mysql2Adapter"
                      ActiveRecord::DynamicTimeout::Mysql2AdapterExtension
                    when "ActiveRecord::ConnectionAdapters::TrilogyAdapter"
                      ActiveRecord::DynamicTimeout::TrilogyAdapterExtension
                    when "ActiveRecord::ConnectionAdapters::SQLite3Adapter"
                      ActiveRecord::DynamicTimeout::SqliteAdapterExtension
                    when "ActiveRecord::ConnectionAdapters::PostgreSQLAdapter"
                      ActiveRecord::DynamicTimeout::PostgresAdapterExtension
                    end
        adapter_class.prepend(extension) if extension
      end
    end
  end
end

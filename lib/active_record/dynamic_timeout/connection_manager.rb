# frozen_string_literal: true

module ActiveRecord::DynamicTimeout
  class ConnectionManager
    class << self
      # @return [Class]
      def timeout_manager
        @timeout_manager or raise "No adapter set"
      end

      # @param [Class] adapter_class
      def set_timeout_manager(adapter_class:)
        @timeout_manager = @adapters[adapter_class.name] or raise "No adapter registered for #{adapter_class.name}, registered adapters: #{@adapters.keys}"
      end

      # @param [String] adapter_class_name
      # @param [Class] timeout_manager_class
      def register_adapter(adapter_class_name, timeout_manager_class)
        @adapters ||= {}
        @adapters[adapter_class_name] = timeout_manager_class
      end

      def clear_adapters
        @adapters = {}
        @timeout_manager = nil
      end

      # @param [ActiveRecord::ConnectionAdapters::AbstractAdapter] connection
      # @param [Integer, nil] timeout
      def set_timeout(connection, timeout)
        return if connection.active_record_dynamic_timeout == timeout
        if timeout.nil?
          reset_timeout(connection)
        else
          timeout_manager.set_timeout(connection, timeout)
          connection.active_record_dynamic_timeout = timeout
        end
      end

      # @param [ActiveRecord::ConnectionAdapters::AbstractAdapter] connection
      def reset_timeout(connection)
        return if connection.active_record_dynamic_timeout.nil?
        config = connection.instance_variable_get(:@config)
        timeout_manager.reset_timeout(connection, config)
        connection.active_record_dynamic_timeout = nil
      end
    end
  end
end

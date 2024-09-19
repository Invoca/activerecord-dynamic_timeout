# frozen_string_literal: true

require "active_record"
require "active_support"

require_relative "dynamic_timeout/deprecator"

module ActiveRecord
  module DynamicTimeout
    STACK_KEY = :active_record_dynamic_timeout_stack
    CONNECTION_KEY = :active_record_dynamic_timeout_connections

    Thread.attr_accessor :ar_dynamic_timeout_execution_state
    Fiber.attr_accessor :ar_dynamic_timeout_execution_state

    class << self
      # @param [Integer, nil] timeout
      def with(timeout:)
        (timeout.is_a?(Integer) || timeout.nil?) or raise ArgumentError, "timeout must be an Integer or NilClass, got: `#{timeout.inspect}`"
        timeout_stack << timeout
        yield
      ensure
        timeout_stack.pop
      end

      # @return [Integer, nil]
      def current_timeout
        timeout_stack.last
      end

      # @param [Class] scope_class
      def isolation_scope=(scope_class)
        (scope_class == Thread || scope_class == Fiber) or raise ArgumentError, "isolation_scope must be `Thread` or `Fiber`, got: `#{scope_class.inspect}`"
        if ActiveRecord.gem_version >= "7.0"
          deprecator.warn("ActiveRecord::DynamicTimeout.isolation_scope= does not do anything with Rails 7.0+ . Use ActiveSupport::IsolatedExecutionState.isolation_level= instead.")
        end
        @isolation_scope = scope_class
      end

      private

      def timeout_stack
        if (stack = isolation_state[STACK_KEY])
          stack
        else
          stack = []
          isolation_state[STACK_KEY] = stack
          stack
        end
      end

      def isolation_state
        if ActiveRecord.gem_version < "7.0"
          isolation_scope.current.ar_dynamic_timeout_execution_state ||= {}
        else
          ActiveSupport::IsolatedExecutionState
        end
      end

      def isolation_scope
        @isolation_scope ||= if ActiveRecord.gem_version < "7.0"
                               Thread
                             else
                               raise "ActiveRecord::DynamicTimeout.isolation_scope is not supported in Rails 7.0+, use ActiveSupport::IsolatedExecutionState.scope instead"
                             end
      end
    end
  end
end

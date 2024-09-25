# frozen_string_literal: true

require "active_support"
require "active_support/concern"

module ActiveRecord::DynamicTimeout
  module BaseExtension
    extend ActiveSupport::Concern

    module ClassMethods
      # @param [Numeric, NilClass] timeout_seconds The timeout in seconds, or nil to disable the timeout.
      def with_timeout(timeout_seconds)
        (timeout_seconds.is_a?(Numeric) || timeout_seconds.nil?) or raise ArgumentError, "timeout_seconds must be Numeric or NilClass, got: `#{timeout_seconds.inspect}`"
        timeout_stack << timeout_seconds
        yield
      ensure
        timeout_stack.pop
      end

      # @return [Numeric, NilClass] The current timeout in seconds, or nil if no timeout is set.
      def current_timeout_seconds
        timeout_stack.last
      end

      # @param [Class] scope_class
      def timeout_isolation_scope=(scope_class)
        (scope_class == Thread || scope_class == Fiber) or raise ArgumentError, "scope must be `Thread` or `Fiber`, got: `#{scope_class.inspect}`"
        raise ArgumentError, "timeout_isolation_scope can only be set once" if @timeout_isolation_scope
        @timeout_isolation_scope = scope_class
      end

      private

      def timeout_stack
        if (stack = timeout_isolation_state[:active_record_dynamic_timeout_stack])
          stack
        else
          stack = []
          timeout_isolation_state[:active_record_dynamic_timeout_stack] = stack
          stack
        end
      end

      def timeout_isolation_state
        if timeout_isolation_scope == Thread
          Thread.current.thread_variable_get(:ar_dynamic_timeout_execution_state) ||
            Thread.current.thread_variable_set(:ar_dynamic_timeout_execution_state, {})
        else
          # Thread.current[] is Fiber local
          Thread.current[:ar_dynamic_timeout_execution_state] ||= {}
        end
      end

      def timeout_isolation_scope
        @timeout_isolation_scope
      end
    end
  end
end

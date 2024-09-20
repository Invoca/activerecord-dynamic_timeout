# frozen_string_literal: true

require "active_support"
require "active_support/concern"

module ActiveRecord::DynamicTimeout
  module BaseExtension
    extend ActiveSupport::Concern

    module ClassMethods
      def with_timeout(timeout)
        (timeout.is_a?(Integer) || timeout.nil?) or raise ArgumentError, "timeout must be an Integer or NilClass, got: `#{timeout.inspect}`"
        timeout_stack << timeout
        yield
      ensure
        timeout_stack.pop
      end

      def current_timeout
        timeout_stack.last
      end

      # @param [Class] scope_class
      def timeout_isolation_scope=(scope_class)
        (scope_class == Thread || scope_class == Fiber) or raise ArgumentError, "scope must be `Thread` or `Fiber`, got: `#{scope_class.inspect}`"
        raise ArgumentError, "timeout_isolation_scope can only be set once" if @timeout_isolation_scope
        if ActiveRecord.gem_version >= "7.0"
          ActiveRecord.deprecator.warn("ActiveRecord::Base.timeout_isolation_scope= does not do anything with Rails 7.0+ . Use ActiveSupport::IsolatedExecutionState.isolation_level= instead.")
        end
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
        if ActiveRecord.gem_version < "7.0"
          if timeout_isolation_scope == Thread
            Thread.current.thread_variable_get(:ar_dynamic_timeout_execution_state) || Thread.current.thread_variable_set(:ar_dynamic_timeout_execution_state, {})
          else
            # Thread.current[] is Fiber local
            Thread.current[:ar_dynamic_timeout_execution_state] ||= {}
          end
        else
          ActiveSupport::IsolatedExecutionState
        end
      end

      def timeout_isolation_scope
        @timeout_isolation_scope ||= if ActiveRecord.gem_version < "7.0"
                                       Thread
                                     else
                                       raise "ActiveRecord::Base.timeout_isolation_scope is not supported in Rails 7.0+, use ActiveSupport::IsolatedExecutionState.scope instead"
                                     end
      end
    end
  end
end

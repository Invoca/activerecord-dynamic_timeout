# frozen_string_literal: true

require "active_support"
require "active_support/concern"
require_relative "../../dynamic_timeout"

module ActiveRecord::DynamicTimeout
  module AbstractAdapterExtension
    extend ActiveSupport::Concern

    attr_accessor :active_record_dynamic_timeout

    included do
      set_callback :checkin, :before, :reset_dynamic_timeout_for_checkin, prepend: true
    end

      def supports_dynamic_timeouts?
      false
    end

    def set_dynamic_timeout(raw_connection, timeout)
      return unless supports_dynamic_timeouts?
      return if active_record_dynamic_timeout == timeout
      if timeout.nil?
        reset_dynamic_timeout(raw_connection)
      else
        set_connection_timeout(raw_connection, timeout)
        self.active_record_dynamic_timeout = timeout
      end
    end

    def reset_dynamic_timeout(raw_connection)
      return unless supports_dynamic_timeouts?
      return if active_record_dynamic_timeout.nil?
      reset_connection_timeout(raw_connection)
      self.active_record_dynamic_timeout = nil
    end
  end

  module TimeoutAdapterExtension
    def with_raw_connection(*args, **kwargs, &block)
      super do |raw_connection|
        set_dynamic_timeout(raw_connection, ActiveRecord::DynamicTimeout.current_timeout)
        yield raw_connection
      ensure
        if timeout_set_client_side?
          reset_dynamic_timeout(raw_connection)
        end
      end
    end

    # This ensures new connections from reconnects have the correct timeout.
    def configure_connection
      super
      if active_record_dynamic_timeout && !timeout_set_client_side?
        set_connection_timeout(@raw_connection, active_record_dynamic_timeout)
      end
    end

    def reset_dynamic_timeout_for_checkin
      if active_record_dynamic_timeout
        with_raw_connection do |conn|
          reset_dynamic_timeout(conn)
        end
      end
    end
  end

  module TimeoutAdapterExtension_Rails_7_0
    def log(*args, **kwargs, &block)
      super do
        set_dynamic_timeout(@connection, ActiveRecord::DynamicTimeout.current_timeout)
        yield
      ensure
        if timeout_set_client_side?
          reset_dynamic_timeout(@connection)
        end
      end
    end

    # This ensures new connections from reconnects have the correct timeout.
    def configure_connection
      super
      if active_record_dynamic_timeout && !timeout_set_client_side?
        set_connection_timeout(@connection, active_record_dynamic_timeout)
      end
    end

    def reset_dynamic_timeout_for_checkin
      if @connection
        reset_dynamic_timeout(@connection)
      end
    end
  end
end

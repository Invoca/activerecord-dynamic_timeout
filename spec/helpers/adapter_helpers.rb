# frozen_string_literal: true

module AdapterHelpers
  class NullAdapter; end
  class NullTimeoutManager
    class << self
      def set_timeout(_connection, _timeout); end
      def reset_timeout(_connection, _config); end
      def client_side?; false; end
    end
  end

  class ClientSideTimeoutManager < NullTimeoutManager
    class << self
      def client_side?; true; end
    end
  end

  class DummyConnection
    attr_accessor :active_record_dynamic_timeout

    def initialize(config: nil, starting_timeout: nil)
      @config = config
      @active_record_dynamic_timeout = starting_timeout
    end
  end
end

module ActiveRecord::DynamicTimeout
  module Mysql2AdapterExtension
    def set_timeout(timeout)
      @raw_connection
    end
  end
end

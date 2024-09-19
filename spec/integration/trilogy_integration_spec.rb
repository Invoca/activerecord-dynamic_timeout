# frozen_string_literal: true

require "active_record/dynamic_timeout/initializer"

RSpec.describe "Trilogy Integration Tests", skip: (ActiveRecord.gem_version < "7.1" ? "Trilogy Not Supported" : nil) do
  before(:all) do
    configure_database(File.expand_path("../fixtures/trilogy_db_config.yml", __dir__))
    ActiveRecord::DynamicTimeout::Initializer.initialize!
  end

  describe ".with" do
    it "sets the timeout on the connection" do
      expect do
        ActiveRecord::DynamicTimeout.with(timeout: 1) do
          ActiveRecord::Base.connection.  execute("SELECT SLEEP(2)")
        end
      end.to raise_error(ActiveRecord::AdapterTimeout)
    end

    it "ensures the connection timeout is is set after reconnect" do
      ActiveRecord::DynamicTimeout.with(timeout: 1) do
        ActiveRecord::Base.connection.execute("SELECT SLEEP(0)")
        ActiveRecord::Base.connection.reconnect!
        expect do
          ActiveRecord::Base.connection.execute("SELECT SLEEP(2)")
        end.to raise_error(ActiveRecord::AdapterTimeout)
      end
    end

    it "checks connection back in with the correct timeout" do
      connection = ActiveRecord::Base.connection
      ActiveRecord::DynamicTimeout.with(timeout: 1) do
        connection.execute("SELECT SLEEP(0)")
        connection.close
      end
      expect(connection.raw_connection.read_timeout).to eq(60)
      expect(connection.raw_connection.write_timeout).to eq(60)
    end
  end
end

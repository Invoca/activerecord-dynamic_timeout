# frozen_string_literal: true

require "active_record/dynamic_timeout/initializer"

RSpec.describe "Mysql2 Integration Tests", mysql2: true do
  before do
    configure_database(File.expand_path("../fixtures/mysql2_db_config.yml", __dir__))
    ActiveRecord::DynamicTimeout::Initializer.initialize!
  end

  describe ".with" do
    it "sets the timeout on the connection" do
      expect do
        ActiveRecord::Base.with_timeout(1.second) do
          ActiveRecord::Base.connection.execute("SELECT SLEEP(2)")
        end
      end.to raise_error(ActiveRecord::AdapterTimeout)
    end

    it "ensures the connection timeout is is set after reconnect" do
      ActiveRecord::Base.with_timeout(1.second) do
        ActiveRecord::Base.connection.execute("SELECT SLEEP(0)")
        ActiveRecord::Base.connection.reconnect!
        expect do
          ActiveRecord::Base.connection.execute("SELECT SLEEP(2)")
        end.to raise_error(ActiveRecord::AdapterTimeout)
      end
    end

    it "checks connection back in with the correct timeout" do
      connection = ActiveRecord::Base.connection
      ActiveRecord::Base.with_timeout(1.second) do
        connection.execute("SELECT SLEEP(0)")
        connection.close
      end
      expect(connection.raw_connection.instance_variable_get(:@read_timeout)).to eq(60)
      expect(connection.raw_connection.instance_variable_get(:@write_timeout)).to eq(60)
    end
  end
end

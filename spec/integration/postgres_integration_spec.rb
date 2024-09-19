# frozen_string_literal: true

require "active_record/dynamic_timeout/initializer"

RSpec.describe "Postgres Integration Tests" do
  before(:all) do
    configure_database(File.expand_path("../fixtures/postgres_db_config.yml", __dir__))
    ActiveRecord::DynamicTimeout::Initializer.initialize!
  end

  describe ".with" do
    it "sets the timeout on the connection" do
      expect do
        ActiveRecord::Base.with_timeout(1) do
          ActiveRecord::Base.connection.execute("SELECT PG_SLEEP(2)")
        end
      end.to raise_error(ActiveRecord::QueryCanceled)
    end

    it "ensures the connection timeout is is set after reconnect" do
      ActiveRecord::Base.with_timeout(100) do
        ActiveRecord::Base.connection.execute("SELECT PG_SLEEP(0)")
        ActiveRecord::Base.connection.reconnect!
        expect do
          ActiveRecord::Base.connection.execute("SELECT PG_SLEEP(2)")
        end.to raise_error(ActiveRecord::QueryCanceled)
      end
    end

    it "checks connection back in with the correct timeout" do
      connection = ActiveRecord::Base.connection
      ActiveRecord::Base.with_timeout(1000) do
        connection.execute("SELECT PG_SLEEP(0)")
        connection.close
      end
      expect(connection.raw_connection.query("select setting from pg_settings where name = 'statement_timeout'").first).to eq({ "setting" => "10000" })
    end
  end
end

# frozen_string_literal: true

require "active_record/dynamic_timeout/initializer"

RSpec.describe "Mysql2 Integration Tests" do
  before do
    configure_database(File.expand_path("../fixtures/mysql2_db_config.yml", __dir__))
    ActiveRecord::DynamicTimeout::Initializer.initialize!
  end

  describe ".with" do
    it "sets the timeout on the connection" do
      expect do
        ActiveRecord::DynamicTimeout.with(timeout: 1) do
          ActiveRecord::Base.connection.execute("SELECT SLEEP(2)")
        end
      end.to raise_error(ActiveRecord::StatementInvalid)
    end

    it "resets the connection timeout on checkin" do
      conn = ActiveRecord::Base.connection
      ActiveRecord::DynamicTimeout.with(timeout: 5) do
        conn.execute("SELECT SLEEP(0)")
        ActiveRecord::Base.connection_pool.release_connection
      end
    end
  end
end

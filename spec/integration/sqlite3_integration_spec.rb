# frozen_string_literal: true

require "active_record/dynamic_timeout/initializer"

RSpec.describe "Sqlite3 Integration Tests", sqlite: true do
  before(:all) do
    configure_database(File.expand_path("../fixtures/sqlite_db_config.yml", __dir__))
    ActiveRecord::DynamicTimeout::Initializer.initialize!
  end

  describe ".with" do
    it "sets the lock timeout on the connection" do
      ActiveRecord::Base.connection.execute(<<-SQL)
        CREATE TABLE IF NOT EXISTS test_table (id INTEGER PRIMARY KEY);
      SQL
      thread = Thread.new do
        ActiveRecord::Base.connection.transaction do
          ActiveRecord::Base.connection.exec_query("INSERT INTO test_table DEFAULT VALUES;")
          sleep(0.5)
        end
      end
      sleep(0.2)
      expect do
        ActiveRecord::Base.with_timeout(100) do
          conn = ActiveRecord::Base.connection
          conn.execute("select 1")
          conn.execute(<<-SQL)
            INSERT INTO test_table DEFAULT VALUES;
          SQL
        end
      end.to raise_error(ActiveRecord::StatementInvalid, /database is locked/)
    ensure
      thread.join
    end
  end

  it "checks connection back in with the correct busy_timeout" do
    connection = ActiveRecord::Base.connection
    ActiveRecord::Base.with_timeout(2000) do
      connection.execute("SELECT 1")
      connection.close
    end
    expect(connection.raw_connection.get_int_pragma("busy_timeout")).to eq(5000)
  end
end

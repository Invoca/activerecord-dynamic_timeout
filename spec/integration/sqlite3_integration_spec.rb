# frozen_string_literal: true

require "active_record/dynamic_timeout/initializer"

RSpec.describe "Sqlite3 Integration Tests" do
  before do
    configure_database(File.expand_path("../fixtures/sqlite_db_config.yml", __dir__))
    ActiveRecord::DynamicTimeout::Initializer.initialize!
  end

  describe ".with" do
    it "sets the lock timeout on the connection" do
      ActiveRecord::Base.connection.execute(<<-SQL)
        CREATE TABLE IF NOT EXISTS test_table (id INTEGER PRIMARY KEY);
      SQL
      thread = Thread.new do
        ActiveRecord::Base.connection.raw_connection.create_function("sleep", 1) do |_func, time|
          sleep(time)
        end
        ActiveRecord::Base.connection.exec_query("BEGIN IMMEDIATE TRANSACTION;")
        ActiveRecord::Base.connection.exec_query("INSERT INTO test_table DEFAULT VALUES;")
        ActiveRecord::Base.connection.exec_query("SELECT sleep(2);")
        ActiveRecord::Base.connection.exec_query("COMMIT TRANSACTION;")
      end
      sleep(0.2)
      expect do
        ActiveRecord::DynamicTimeout.with(timeout: 1000) do
          ActiveRecord::Base.connection.execute(<<-SQL)
            INSERT INTO test_table DEFAULT VALUES;
          SQL
        end
      end.to raise_error(ActiveRecord::StatementInvalid)
      thread.join
    end
  end
end

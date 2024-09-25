# frozen_string_literal: true

require "active_record/dynamic_timeout/initializer"
require "sqlite3"

RSpec.describe "Sqlite3 Integration Tests", sqlite: true, skip: SQLite3::VERSION < "2" ? "SQLite3 version #{SQLite3::VERSION} not supported" : nil do
  before(:all) do
    configure_database(File.expand_path("../fixtures/sqlite_db_config.yml", __dir__))
    ActiveRecord::DynamicTimeout::Initializer.initialize!
    ActiveRecord::Base.connection.drop_table(:test_table, if_exists: true)
    ActiveRecord::Base.connection.create_table(:test_table)
  end

  before do
    ActiveRecord::Base.connection.truncate_tables(:test_table)
    ActiveRecord::Base.connection.transaction do
      2_000.times do
        ActiveRecord::Base.connection.execute("INSERT INTO test_table DEFAULT VALUES")
      end
    end
  end

  describe ".with" do
    it "sets the lock timeout on the connection" do
      expect do
        ActiveRecord::Base.with_timeout(0.001.seconds) do
          ActiveRecord::Base.connection.execute("SELECT * FROM test_table")
        end
      end.to raise_error(ActiveRecord::StatementInvalid, /interrupted/)
    end
  end

  it "properly resets the statement timeout when the connection is checked in" do
    connection = ActiveRecord::Base.connection
    ActiveRecord::Base.with_timeout(1.seconds) do
      connection.execute("SELECT 1")
      connection.close
    end
    connection.execute("SELECT * from test_table")
  end

  it "properly resets the statment timeout after an error" do
    connection = ActiveRecord::Base.connection
    expect do
      ActiveRecord::Base.with_timeout(0.001.seconds) do
        connection.execute("SELECT * FROM test_table")
      end
    end.to raise_error(ActiveRecord::StatementInvalid, /interrupted/)
    expect do
      connection.execute("SELECT * FROM test_table")
    end.to_not raise_error
  end
end

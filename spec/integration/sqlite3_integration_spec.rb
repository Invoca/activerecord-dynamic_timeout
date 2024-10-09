# frozen_string_literal: true

require "active_record/dynamic_timeout/initializer"
require "sqlite3"

RSpec.describe "Sqlite3 Integration Tests", sqlite: true, skip: SQLite3::VERSION < "2" ? "SQLite3 version #{SQLite3::VERSION} not supported" : nil do
  before(:all) do
    configure_database(File.expand_path("../fixtures/sqlite_db_config.yml", __dir__))
    ActiveRecord::DynamicTimeout::Initializer.initialize!
  end

  before do
    create_test_model_table
    ActiveRecord::Base.connection.transaction do
      2_000.times { TestModel.create! }
    end
  end

  it "sets the lock timeout on the connection" do
    expect do
      ActiveRecord::Base.with_timeout(0.001.seconds) do
        TestModel.all.to_a
      end
    end.to raise_error(ActiveRecord::StatementInvalid, /interrupted/)
  end

  it "properly resets the statement timeout when the connection is checked in" do
    connection = ActiveRecord::Base.connection
    ActiveRecord::Base.with_timeout(1.seconds) do
      connection.execute("SELECT 1")
      connection.close
    end
    TestModel.all.to_a
  end

  it "properly resets the statment timeout after an error" do
    expect do
      ActiveRecord::Base.with_timeout(0.001.seconds) do
        TestModel.all.to_a
      end
    end.to raise_error(ActiveRecord::StatementInvalid, /interrupted/)
    expect do
      TestModel.all.to_a
    end.to_not raise_error
  end
end

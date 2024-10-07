# frozen_string_literal: true

require "active_record/dynamic_timeout/initializer"

RSpec.describe "Postgres Integration Tests", postgresql: true do
  before(:all) do
    configure_database(File.expand_path("../fixtures/postgres_db_config.yml", __dir__))
    ActiveRecord::DynamicTimeout::Initializer.initialize!
    create_test_model_table
  end

  def lock_table(seconds)
    Thread.new do
      ActiveRecord::Base.transaction do
        ActiveRecord::Base.connection.execute("LOCK TABLE test_models IN ACCESS EXCLUSIVE MODE")
        sleep seconds
      end
    end
    sleep(0.1) # Ensure thread has locked the table before returning
  end

  describe ".with" do
    it "sets the timeout on the connection" do
      expect do
        ActiveRecord::Base.with_timeout(0.01.seconds) do
          ActiveRecord::Base.connection.execute("SELECT PG_SLEEP(2)")
        end
      end.to raise_error(ActiveRecord::QueryCanceled)
    end

    context "timeout error is raised within a transaction" do
      it "properly rolls back" do
        expect(TestModel.count).to eq(0)
        lock_table(0.4.seconds)
        expect do
          ActiveRecord::Base.with_timeout((0.1).second) do
            ActiveRecord::Base.transaction do
              TestModel.create!
            end
          end
        end.to raise_error(ActiveRecord::QueryCanceled)
        expect(TestModel.count).to eq(0)
      end
    end

    it "ensures the connection timeout is is set after reconnect" do
      ActiveRecord::Base.with_timeout(0.1.seconds) do
        ActiveRecord::Base.connection.execute("SELECT PG_SLEEP(0)")
        ActiveRecord::Base.connection.reconnect!
        expect do
          ActiveRecord::Base.connection.execute("SELECT PG_SLEEP(2)")
        end.to raise_error(ActiveRecord::QueryCanceled)
      end
    end

    it "checks connection back in with the correct timeout" do
      connection = ActiveRecord::Base.connection
      ActiveRecord::Base.with_timeout(1.second) do
        connection.execute("SELECT PG_SLEEP(0)")
        connection.close
      end
      expect(connection.raw_connection.query("select setting from pg_settings where name = 'statement_timeout'").first).to eq({ "setting" => "10000" })
    end
  end
end

# frozen_string_literal: true

require "active_record/dynamic_timeout/initializer"

RSpec.describe "Postgres Integration Tests" do
  before do
    configure_database(File.expand_path("../fixtures/postgres_db_config.yml", __dir__))
    ActiveRecord::DynamicTimeout::Initializer.initialize!
  end

  describe ".with" do
    it "sets the timeout on the connection" do
      expect do
        ActiveRecord::DynamicTimeout.with(timeout: 1) do
          ActiveRecord::Base.connection.execute("SELECT PG_SLEEP(2)")
        end
      end.to raise_error(ActiveRecord::QueryCanceled)
    end
  end
end

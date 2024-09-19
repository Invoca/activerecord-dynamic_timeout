# frozen_string_literal: true

require "active_record/dynamic_timeout/initializer"

RSpec.describe "Trilogy Integration Tests", skip: ActiveRecord.gem_version < "7.1" do
  before do
    configure_database(File.expand_path("../fixtures/trilogy_db_config.yml", __dir__))
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
  end
end

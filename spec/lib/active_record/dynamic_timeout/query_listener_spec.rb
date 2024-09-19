# frozen_string_literal: true

require "active_record/dynamic_timeout/query_listener"
require "active_record/dynamic_timeout/connection_manager"

RSpec.describe ActiveRecord::DynamicTimeout::QueryListener do
  before do
    ActiveRecord::DynamicTimeout::ConnectionManager.clear_adapters
  end

  describe "#start" do
    subject(:start) { listener.start("sql.active_record", "1", notification_payload) }
    let(:listener) { described_class.new }
    let(:notification_payload) { { name: name, sql: sql_query, connection: connection } }
    let(:name) { "SCHEMA" }
    let(:sql_query) { "sql query" }
    let(:connection) { AdapterHelpers::DummyConnection.new }

    context "when there is no connection" do
      let(:connection) { nil }

      it "does not set the timeout" do
        expect(ActiveRecord::DynamicTimeout::ConnectionManager).to_not receive(:set_timeout)
        start
      end
    end

    context "when the name starts with 'DYNAMIC_TIMEOUT'" do
      let(:name) { "DYNAMIC_TIMEOUT" }

      it "does not set the timeout" do
        expect(ActiveRecord::DynamicTimeout::ConnectionManager).to_not receive(:set_timeout)
        start
      end
    end

    context "when there is a connection" do
      it "sets the timeout to the current timeout" do
        expect(ActiveRecord::DynamicTimeout::ConnectionManager).to receive(:set_timeout).with(connection, ActiveRecord::DynamicTimeout.current_timeout).and_call_original
        start
      end
    end
  end

  describe "#finish" do
    subject(:finish) { listener.finish("sql.active_record", "1", notification_payload) }
    let(:listener) { described_class.new }
    let(:notification_payload) { { name: name, sql: sql_query, connection: connection } }
    let(:name) { "SCHEMA" }
    let(:sql_query) { "sql query" }
    let(:connection) { AdapterHelpers::DummyConnection.new }
    let(:timeout_manager) { AdapterHelpers::NullTimeoutManager }

    before do
      ActiveRecord::DynamicTimeout::ConnectionManager.register_adapter(AdapterHelpers::DummyConnection.name, timeout_manager)
      ActiveRecord::DynamicTimeout::ConnectionManager.set_timeout_manager(adapter_class: AdapterHelpers::DummyConnection)
    end

    context "when there is no connection" do
      let(:connection) { nil }

      it "does not set the timeout" do
        expect(ActiveRecord::DynamicTimeout::ConnectionManager).to_not receive(:set_timeout)
        finish
      end
    end

    context "when the name starts with 'DYNAMIC_TIMEOUT'" do
      let(:name) { "DYNAMIC_TIMEOUT" }

      it "does not set the timeout" do
        expect(ActiveRecord::DynamicTimeout::ConnectionManager).to_not receive(:set_timeout)
        finish
      end
    end

    context "when the adapter sets the timeout on the client" do
      let(:timeout_manager) { AdapterHelpers::ClientSideTimeoutManager }

      it "resets the timeout on the connection" do
        expect(ActiveRecord::DynamicTimeout::ConnectionManager).to receive(:reset_timeout).with(connection).and_call_original
        finish
      end
    end

    context "when the adapter requires a query to set the timeout" do
      it "does not reset the timeout on the connection" do
        expect(ActiveRecord::DynamicTimeout::ConnectionManager).to_not receive(:reset_timeout)
        finish
      end
    end
  end
end

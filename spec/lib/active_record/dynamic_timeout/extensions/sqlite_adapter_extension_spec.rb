# frozen_string_literal: true

require "active_record/dynamic_timeout/extensions/sqlite_adapter_extension"

RSpec.describe ActiveRecord::DynamicTimeout::SqliteAdapterExtension, sqlite: true do
  require "active_record/connection_adapters/sqlite3_adapter"
  let(:adapter_klass) do
    Class.new(ActiveRecord::ConnectionAdapters::SQLite3Adapter) do
      class << self
        def name
          "SqliteDummyAdapter"
        end
      end

      def initialize(config)
        @config = config
      end
    end.prepend(described_class)
  end
  let(:adapter) { adapter_klass.new(config) }
  let(:config) { {} }
  let(:connection) { connection_klass.new }
  let(:connection_klass) do
    Class.new do
      attr_reader :timeout
      def busy_timeout(timeout)
        @timeout = timeout
      end
    end
  end

  describe "#set_connection_timeout" do
    subject(:set_connection_timeout) { adapter.set_connection_timeout(connection, timeout) }

    let(:timeout) { 10 }

    it "sets the timeout to the timeout" do
      set_connection_timeout
      expect(connection.timeout).to eq(10)
    end

    context "when timeout is nil" do
      let(:timeout) { nil }

      it "sets the timeout to 0" do
        set_connection_timeout
        expect(connection.timeout).to eq(0)
      end
    end
  end

  describe "#reset_connection_timeout" do
    subject(:reset_connection_timeout) { adapter.reset_connection_timeout(connection) }

    context "when timeout is set in the config" do
      let(:config) { { timeout: 20 } }

      it "resets the timeout to the value in the config" do
        reset_connection_timeout
        expect(connection.timeout).to eq(20)
      end
    end

    context "when timeout in the config is a numeric string" do
      let(:config) { { timeout: "20" } }

      it "resets the timeout to the value in the config" do
        reset_connection_timeout
        expect(connection.timeout).to eq(20)
      end
    end

    context "when timeout is not set in the config" do
      it "sets the timeout to 0" do
        reset_connection_timeout
        expect(connection.timeout).to eq(0)
      end
    end
  end

  describe "#timeout_set_client_side?" do
    it { expect(adapter.timeout_set_client_side?).to be_falsey }
  end

  describe "#supports_dynamic_timeouts?" do
    it { expect(adapter.supports_dynamic_timeouts?).to be_truthy }
  end
end

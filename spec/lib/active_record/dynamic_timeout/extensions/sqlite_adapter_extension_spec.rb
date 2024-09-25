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

      def initialize; end
    end.include(described_class)
  end
  let(:adapter) { adapter_klass.new }
  let(:connection) { connection_klass.new }
  let(:connection_klass) do
    Class.new do
      attr_reader :timeout
      def statement_timeout=(timeout)
        @timeout = timeout
      end
    end
  end

  describe "#set_connection_timeout" do
    subject(:set_connection_timeout) { adapter.set_connection_timeout(connection, timeout) }

    let(:timeout) { 10 }

    it "sets the timeout to the timeout in milliseconds" do
      set_connection_timeout
      expect(connection.timeout).to eq(10_000)
    end

    context "when timeout is nil" do
      let(:timeout) { nil }

      it "sets the timeout to 0" do
        set_connection_timeout
        expect(connection.timeout).to eq(0)
      end
    end

    context "when timeout is a float" do
      let(:timeout) { 10.5 }
      it "sets the timeout to the timeout in milliseconds as an integer" do
        set_connection_timeout
        expect(connection.timeout).to eq(10_500)
      end
    end

    context "when timeout is a ActiveSupport::Duration" do
      let(:timeout) { 10.seconds }
      it "sets the timeout to the timeout in milliseconds as an integer" do
        set_connection_timeout
        expect(connection.timeout).to eq(10_000)
      end
    end
  end

  describe "#reset_connection_timeout" do
    subject(:reset_connection_timeout) { adapter.reset_connection_timeout(connection) }

    it "sets the timeout to 0" do
      reset_connection_timeout
      expect(connection.timeout).to eq(0)
    end
  end

  describe "#timeout_set_client_side?" do
    it { expect(adapter.timeout_set_client_side?).to be_truthy }
  end

  describe "#supports_dynamic_timeouts?" do
    context "when SQLite3 version is greater than or equal to 2" do
      before do
        stub_const("SQLite3::VERSION", "2.0.0")
      end
      it { expect(adapter.supports_dynamic_timeouts?).to be_truthy }
    end

    context "when Sqlite3 version is less than 2" do
      before do
        stub_const("SQLite3::VERSION", "1.4.0")
      end

      it { expect(adapter.supports_dynamic_timeouts?).to be_falsey }
    end
  end
end

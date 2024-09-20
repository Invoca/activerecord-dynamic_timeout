# frozen_string_literal: true

require "active_record/connection_adapters/postgresql_adapter"
require "active_record/dynamic_timeout/extensions/postgres_adapter_extension"

RSpec.describe ActiveRecord::DynamicTimeout::PostgresAdapterExtension do
  let(:adapter_klass) do
    Class.new(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter) do
      class << self
        def name
          "PostgresDummyAdapter"
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
      attr_reader :last_query
      def query(sql)
        @last_query = sql
      end
    end
  end

  describe "#set_connection_timeout" do
    subject(:set_connection_timeout) { adapter.set_connection_timeout(connection, timeout) }

    let(:timeout) { 10 }

    it "sets the session statement timeout to the timeout" do
      set_connection_timeout
      expect(connection.last_query).to eq("SET SESSION statement_timeout TO 10")
    end

    context "when timeout is nil" do
      let(:timeout) { nil }

      it "sets the session statement timeout to the default" do
        set_connection_timeout
        expect(connection.last_query).to eq("SET SESSION statement_timeout TO DEFAULT")
      end
    end

    context "when timeout is :default" do
      let(:timeout) { :default }

      it "sets the session statement timeout to the default" do
        set_connection_timeout
        expect(connection.last_query).to eq("SET SESSION statement_timeout TO DEFAULT")
      end
    end

    context "when timeout is ':default'" do
      let(:timeout) { ":default" }

      it "sets the session statement timeout to the default" do
        set_connection_timeout
        expect(connection.last_query).to eq("SET SESSION statement_timeout TO DEFAULT")
      end
    end
  end

  describe "#reset_connection_timeout" do
    subject(:reset_connection_timeout) { adapter.reset_connection_timeout(connection) }

    context "when statement_timeout variable is set in the config" do
      let(:config) { { variables: { statement_timeout: 20 }} }

      it "resets the statement_timeout to the value in the config" do
        reset_connection_timeout
        expect(connection.last_query).to eq("SET SESSION statement_timeout TO 20")
      end
    end

    context "when statement_timeout variable is not set in the config" do
      it "resets the statement_timeout to the default" do
        reset_connection_timeout
        expect(connection.last_query).to eq("SET SESSION statement_timeout TO DEFAULT")
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

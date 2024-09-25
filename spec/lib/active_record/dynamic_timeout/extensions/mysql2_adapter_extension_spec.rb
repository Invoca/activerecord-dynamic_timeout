# frozen_string_literal: true

require "active_record/dynamic_timeout/extensions/mysql2_adapter_extension"

RSpec.describe ActiveRecord::DynamicTimeout::Mysql2AdapterExtension, mysql2: true do
  let(:adapter_klass) do
    Class.new do
      class << self
        def name
          "Mysql2DummyAdapter"
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
      attr_reader :read_timeout, :write_timeout
    end
  end

  describe "#set_connection_timeout" do
    subject(:set_connection_timeout) { adapter.set_connection_timeout(connection, timeout) }
    let(:timeout) { 10 }

    it "sets the read and write timeout instance variables" do
      set_connection_timeout
      expect(connection.read_timeout).to eq(10)
      expect(connection.write_timeout).to eq(10)
    end

    context "when timeout is a float" do
      let(:timeout) { 10.1 }
      it "sets the read and write timeout instance variables as the next highest integer" do
        set_connection_timeout
        expect(connection.read_timeout).to eq(11)
        expect(connection.write_timeout).to eq(11)
      end
    end

    context "when timeout is a ActiveSupport::Duration" do
      let(:timeout) { 10.seconds }
      it "sets the read and write timeout instance variables as integers" do
        set_connection_timeout
        expect(connection.read_timeout).to eq(10)
        expect(connection.write_timeout).to eq(10)
      end
    end
  end

  describe "#reset_connection_timeout" do
    subject(:reset_connection_timeout) { adapter.reset_connection_timeout(connection) }

    context "when read_timeout and write_timeout are set in the config" do
      let(:config) { { read_timeout: 10, write_timeout: 20 } }

      it "resets the read and write timeout instance variables" do
        reset_connection_timeout
        expect(connection.read_timeout).to eq(10)
        expect(connection.write_timeout).to eq(20)
      end
    end

    context "when read_timeout and write_timeout are not set in the config" do
      it "resets the read and write timeout instance variables to nil" do
        reset_connection_timeout
        expect(connection.read_timeout).to be_nil
        expect(connection.write_timeout).to be_nil
      end
    end
  end

  describe "#timeout_set_client_side?" do
    it { expect(adapter.timeout_set_client_side?).to be_truthy }
  end

  describe "#supports_dynamic_timeouts?" do
    it { expect(adapter.supports_dynamic_timeouts?).to be_truthy }
  end
end

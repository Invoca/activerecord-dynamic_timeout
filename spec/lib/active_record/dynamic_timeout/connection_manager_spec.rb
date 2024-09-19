# frozen_string_literal: true

require "active_record/dynamic_timeout/connection_manager"

RSpec.describe ActiveRecord::DynamicTimeout::ConnectionManager do
  before do
    described_class.clear_adapters
  end

  describe ".set_timeout_manager" do
    context "when adapter is registered" do
      before do
        described_class.register_adapter(AdapterHelpers::NullAdapter.name, AdapterHelpers::NullTimeoutManager)
      end

      it "sets the timeout_manager" do
        described_class.set_timeout_manager(adapter_class: AdapterHelpers::NullAdapter)
        expect(described_class.timeout_manager).to eq(AdapterHelpers::NullTimeoutManager)
      end
    end

    context "when adapter is not registered" do
      it "raises an error" do
        expect { described_class.set_timeout_manager(adapter_class: AdapterHelpers::NullAdapter) }.to raise_error(/No adapter registered for AdapterHelpers::NullAdapter/)
      end
    end
  end

  describe ".register_adapter" do
    subject(:register_adapter) { described_class.register_adapter(AdapterHelpers::NullAdapter.name, AdapterHelpers::NullTimeoutManager) }

    it "allows setting the timeout manager" do
      register_adapter
      described_class.set_timeout_manager(adapter_class: AdapterHelpers::NullAdapter)
      expect(described_class.timeout_manager).to eq(AdapterHelpers::NullTimeoutManager)
    end
  end

  describe ".set_timeout" do
    before do
      described_class.register_adapter(AdapterHelpers::NullAdapter.name, AdapterHelpers::NullTimeoutManager)
      described_class.set_timeout_manager(adapter_class: AdapterHelpers::NullAdapter)
    end

    subject(:set_timeout) { described_class.set_timeout(connection, timeout) }
    let(:connection) do
      AdapterHelpers::DummyConnection.new(config:, starting_timeout: starting_timeout)
    end
    let(:config) { nil }
    let(:starting_timeout) { nil }
    let(:timeout) { 1 }

    context "when connection has no timeout" do
      it "calls set timeout on the adapter" do
        expect(AdapterHelpers::NullTimeoutManager).to receive(:set_timeout).with(connection, timeout).and_call_original
        set_timeout
      end

      it "sets the connection's timeout instance variable" do
        set_timeout
        expect(connection.active_record_dynamic_timeout).to eq(timeout)
      end
    end

    context "when connection has a timeout" do
      let(:starting_timeout) { 1 }

      context "and setting the same timeout" do
        let(:timeout) { 1 }

        it "does not call set timeout on the adapter" do
          expect(AdapterHelpers::NullTimeoutManager).not_to receive(:set_timeout)
          set_timeout
        end
      end

      context "and setting a different timeout" do
        let(:timeout) { 2 }

        it "calls set timeout on the adapter" do
          expect(AdapterHelpers::NullTimeoutManager).to receive(:set_timeout).with(connection, timeout).and_call_original
          set_timeout
        end

        it "sets the connection's timeout instance variable" do
          set_timeout
          expect(connection.active_record_dynamic_timeout).to eq(timeout)
        end
      end

      context "and setting a nil timeout" do
        let(:timeout) { nil }

        it "calls reset_timeout" do
          expect(described_class).to receive(:reset_timeout).with(connection).and_call_original
          set_timeout
        end
      end
    end
  end

  describe ".reset_timeout" do
    subject(:reset_timeout) { described_class.reset_timeout(connection) }

    before do
      described_class.register_adapter(AdapterHelpers::NullAdapter.name, AdapterHelpers::NullTimeoutManager)
      described_class.set_timeout_manager(adapter_class: AdapterHelpers::NullAdapter)
    end
    let(:connection) do
      AdapterHelpers::DummyConnection.new(config: config, starting_timeout: timeout)
    end
    let(:config) { {} }

    context "when connection has a timeout" do
      let(:timeout) { 1}

      it "calls reset_timeout on the adapter" do
        expect(AdapterHelpers::NullTimeoutManager).to receive(:reset_timeout).with(connection, config).and_call_original
        reset_timeout
      end

      it "clears the connection's timeout instance variable" do
        reset_timeout
        expect(connection.active_record_dynamic_timeout).to be_nil
      end
    end

    context "when connection has no timeout" do
      let(:timeout) { nil }

      it "does not call reset_timeout on the adapter" do
        expect(AdapterHelpers::NullTimeoutManager).not_to receive(:reset_timeout)
        reset_timeout
      end
    end
  end
end

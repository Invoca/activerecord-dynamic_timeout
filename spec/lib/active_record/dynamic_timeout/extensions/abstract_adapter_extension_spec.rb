# frozen_string_literal: true

require "active_record/dynamic_timeout/extensions/abstract_adapter_extension"
require "active_record/dynamic_timeout/extensions/base_extension"

RSpec.describe ActiveRecord::DynamicTimeout::AbstractAdapterExtension do
  before(:all) do
    ActiveRecord::Base.include(ActiveRecord::DynamicTimeout::BaseExtension)
  end

  let(:adapter_klass) do
    Class.new(ActiveRecord::ConnectionAdapters::AbstractAdapter) do
      include ActiveRecord::DynamicTimeout::AbstractAdapterExtension

      class << self
        def self.name
          "DummyAdapter"
        end
      end

      attr_reader :configured

      def initialize; end

      def set_connection_timeout(connection, timeout)
        connection.set_timeout(timeout)
      end

      def reset_connection_timeout(connection)
        connection.reset_timeout
      end

      def timeout_set_client_side?
        true
      end

      def inspect
        "#<#{self.class.name}>"
      end
    end.tap do |klass|
      if support_dynamic_timeouts
        klass.class_eval do
          def supports_dynamic_timeouts?
            true
          end
        end
      end
    end
  end
  let(:adapter) do
    adapter_klass.new
  end
  let(:support_dynamic_timeouts) { false }

  describe "#active_record_dynamic_timeout" do
    it { expect(adapter).to respond_to(:active_record_dynamic_timeout) }
    it { expect(adapter).to respond_to(:active_record_dynamic_timeout=) }
  end

  describe "callbacks" do
    it "defines a checkin callback to reset the dynamic timeout" do
      expect(adapter._checkin_callbacks.map(&:filter)).to include(:reset_dynamic_timeout_for_checkin)
    end
  end

  describe "#supports_dynamic_timeouts?" do
    it "returns false by default" do
      expect(adapter.supports_dynamic_timeouts?).to eq(false)
    end
  end

  describe "#set_dynamic_timeout" do
    subject(:set_dynamic_timeout) do
      adapter.set_dynamic_timeout(raw_connection_double, timeout)
    end
    let(:raw_connection_double) { double }
    let(:timeout) { 10 }
    context "when the adapter does not support dynamic timeouts" do
      it "does nothing" do
        set_dynamic_timeout
        expect(adapter.active_record_dynamic_timeout).to be_nil
      end
    end

    context "when the adapter supports dynamic timeouts" do
      let(:support_dynamic_timeouts) { true }

      context "when timeout is already set" do
        before do
          adapter.active_record_dynamic_timeout = 10
        end

        context "setting the timeout to the same value" do
          it "does nothing" do
            set_dynamic_timeout
            expect(adapter.active_record_dynamic_timeout).to eq(10)
          end
        end

        context "setting the timeout to nil" do
          let(:timeout) { nil }

          it "resets the raw connection timeout" do
            expect(raw_connection_double).to receive(:reset_timeout)
            set_dynamic_timeout
            expect(adapter.active_record_dynamic_timeout).to be_nil
          end
        end

        context "setting the timeout to a new value" do
          let(:timeout) { 20 }

          it "sets the raw connection timeout" do
            expect(raw_connection_double).to receive(:set_timeout).with(20)
            set_dynamic_timeout
            expect(adapter.active_record_dynamic_timeout).to eq(20)
          end
        end
      end
    end
  end

  describe "#reset_dynamic_timeout" do
    subject(:reset_dynamic_timeout) do
      adapter.reset_dynamic_timeout(raw_connection_double)
    end
    let(:raw_connection_double) { double }
    context "when the adapter does not support dynamic timeouts" do
      it "does nothing" do
        reset_dynamic_timeout
        expect(adapter.active_record_dynamic_timeout).to be_nil
      end
    end

    context "when the adapter supports dynamic timeouts" do
      let(:support_dynamic_timeouts) { true }

      context "when timeout is already set" do
        before do
          adapter.active_record_dynamic_timeout = 10
        end

        it "resets the raw connection timeout" do
          expect(raw_connection_double).to receive(:reset_timeout)
          reset_dynamic_timeout
          expect(adapter.active_record_dynamic_timeout).to be_nil
        end
      end

      context "when timeout is not set" do
        it "does nothing" do
          reset_dynamic_timeout
          expect(adapter.active_record_dynamic_timeout).to be_nil
        end
      end
    end
  end

  describe "TimeoutAdapterExtension" do
    before do
      adapter_klass.class_eval do
        def with_raw_connection(*args, **kwargs, &block)
          yield "raw_connection"
        end

        def configure_connection
          @raw_connection = "raw_connection"
        end
      end
      adapter_klass.prepend(ActiveRecord::DynamicTimeout::TimeoutAdapterExtension)
    end

    describe "#with_raw_connection" do
      subject(:with_raw_connection) do
        adapter.with_raw_connection(&with_block)
      end

      let(:with_block) { ->(raw_connection) { raw_connection } }

      it "sets the dynamic timeout" do
        expect(adapter).to receive(:set_dynamic_timeout).with("raw_connection", nil).and_call_original
        with_raw_connection
      end

      context "when timeout is set client side" do
        it "resets the dynamic timeout" do
          expect(adapter).to receive(:reset_dynamic_timeout).with("raw_connection").and_call_original
          with_raw_connection
        end

        context "and the block errors" do
          let(:with_block) { ->(raw_connection) { raise "error" } }

          it "resets the dynamic timeout" do
            expect(adapter).to receive(:reset_dynamic_timeout).with("raw_connection").and_call_original
            expect { with_raw_connection }.to raise_error("error")
          end
        end
      end

      context "when timeout is not set client side" do
        before do
          allow(adapter).to receive(:timeout_set_client_side?).and_return(false)
        end

        it "does not reset the dynamic timeout" do
          expect(adapter).not_to receive(:reset_dynamic_timeout)
          with_raw_connection
        end
      end
    end

    describe "#configure_connection" do
      subject(:configure_connection) do
        adapter.configure_connection
      end

      context "when dynamic timeouts are set" do
        before do
          adapter.active_record_dynamic_timeout = 10
        end

        context "when timeout is set client side" do
          it "does not set the connection timeout" do
            expect(adapter).not_to receive(:set_connection_timeout)
            configure_connection
          end
        end

        context "when timeout is not set client side" do
          before do
            allow(adapter).to receive(:timeout_set_client_side?).and_return(false)
          end

          it "directly sets the connection timeout" do
            expect(adapter).to receive(:set_connection_timeout).with("raw_connection", 10)
            configure_connection
          end
        end
      end

      context "when dynamic timeouts are not set" do
        it "does not set the connection timeout" do
          expect(adapter).not_to receive(:set_connection_timeout)
          configure_connection
        end
      end
    end

    describe "#reset_dynamic_timeout_for_checkin" do
      subject(:reset_dynamic_timeout_for_checkin) do
        adapter.reset_dynamic_timeout_for_checkin
      end

      context "when dynamic timeouts are set" do
        before do
          adapter.active_record_dynamic_timeout = 10
        end

        it "resets the dynamic timeout" do
          expect(adapter).to receive(:reset_dynamic_timeout).with("raw_connection").at_least(1).time.and_call_original
          reset_dynamic_timeout_for_checkin
        end
      end

      context "when dynamic timeouts are not set" do
        it "does not reset the dynamic timeout" do
          expect(adapter).not_to receive(:reset_dynamic_timeout)
          reset_dynamic_timeout_for_checkin
        end
      end
    end
  end

  describe "TimeoutAdapterExtension_Rails_7_0" do
    before do
      adapter_klass.class_eval do
        def log(*args, **kwargs, &block)
          @connection = "connection"
          yield
        end

        def configure_connection
          @connection = "connection"
        end
      end
      adapter_klass.prepend(ActiveRecord::DynamicTimeout::TimeoutAdapterExtension_Rails_7_0)
    end

    describe "#log" do
      subject(:log) do
        adapter.log(&log_block)
      end

      let(:log_block) do
        -> { "result" }
      end

      it "sets the dynamic timeout" do
        expect(adapter).to receive(:set_dynamic_timeout).with("connection", nil).and_call_original
        log
      end

      context "when timeout is set client side" do
        it "resets the dynamic timeout" do
          expect(adapter).to receive(:reset_dynamic_timeout).with("connection").and_call_original
          log
        end

        context "and the block errors" do
          let(:log_block) { -> { raise "error" } }

          it "resets the dynamic timeout" do
            expect(adapter).to receive(:reset_dynamic_timeout).with("connection").and_call_original
            expect { log }.to raise_error("error")
          end
        end
      end
    end

    describe "#configure_connection" do
      subject(:configure_connection) do
        adapter.configure_connection
      end

      context "when dynamic timeouts are set" do
        before do
          adapter.active_record_dynamic_timeout = 10
        end

        context "when timeout is set client side" do
          it "does not set the connection timeout" do
            expect(adapter).not_to receive(:set_connection_timeout)
            configure_connection
          end
        end

        context "when timeout is not set client side" do
          before do
            allow(adapter).to receive(:timeout_set_client_side?).and_return(false)
          end

          it "directly sets the connection timeout" do
            expect(adapter).to receive(:set_connection_timeout).with("connection", 10)
            configure_connection
          end
        end
      end

      context "when dynamic timeouts are not set" do
        it "does not set the connection timeout" do
          expect(adapter).not_to receive(:set_connection_timeout)
          configure_connection
        end
      end
    end
  end
end

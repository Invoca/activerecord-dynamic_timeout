# frozen_string_literal: true

require "active_record/dynamic_timeout"

RSpec.describe ActiveRecord::DynamicTimeout do
  before do
    described_class.instance_variable_set(:@isolation_scope, nil)
  end

  it "has a version number" do
    expect(ActiveRecord::DynamicTimeout::VERSION).not_to be nil
  end

  describe ".with" do
    context "when timeout is an integer" do
      it "sets the timeout" do
        described_class.with(timeout: 10) do
          expect(described_class.current_timeout).to eq(10)
        end
      end
    end

    context "when timeout is nil" do
      it "sets the timeout to nil" do
        described_class.with(timeout: nil) do
          expect(described_class.current_timeout).to be_nil
        end
      end
    end

    context "when timeout is not an integer or nil" do
      it "raises an ArgumentError" do
        expect { described_class.with(timeout: "foo") { } }.to raise_error(ArgumentError, /timeout must be an Integer or NilClass/)
      end
    end

    context "with nested calls" do
      it "sets the timeout to the innermost value" do
        described_class.with(timeout: 10) do
          described_class.with(timeout: 20) do
            expect(described_class.current_timeout).to eq(20)
          end
          expect(described_class.current_timeout).to eq(10)
        end
      end

      context "with a nil timeout" do
        it "sets the timeout to nil" do
          described_class.with(timeout: 10) do
            described_class.with(timeout: nil) do
              expect(described_class.current_timeout).to be_nil
            end
            expect(described_class.current_timeout).to eq(10)
          end
        end
      end
    end

    context "when isolation level is set to Thread" do
      before do
        if ActiveRecord.gem_version < "7.0"
          described_class.isolation_scope = Thread
        else
          ActiveSupport::IsolatedExecutionState.isolation_level = :thread
        end
      end

      it "ensures the timeout is isolated to the current thread" do
        described_class.with(timeout: 10) do
          expect(described_class.current_timeout).to eq(10)
          thread = Thread.new do
            expect(described_class.current_timeout).to be_nil
            described_class.with(timeout: 20) do
              expect(described_class.current_timeout).to eq(20)
            end
          end
          thread.join
          expect(described_class.current_timeout).to eq(10)
        end
        expect(described_class.current_timeout).to be_nil
      end

      context "with calls within a Fiber" do
        it "has the same timeout within the fiber that is set in the thread" do
          described_class.with(timeout: 10) do
            expect(described_class.current_timeout).to eq(10)
            fiber = Fiber.new do
              expect(described_class.current_timeout).to eq(10)
              described_class.with(timeout: 20) do
                expect(described_class.current_timeout).to eq(20)
              end
            end
            fiber.resume
            expect(described_class.current_timeout).to eq(10)
          end
          expect(described_class.current_timeout).to be_nil
        end
      end
    end

    context "when isolation level is set to Fiber" do
      before do
        if ActiveRecord.gem_version < "7.0"
          described_class.isolation_scope = Fiber
        else
          ActiveSupport::IsolatedExecutionState.isolation_level = :fiber
        end
      end

      it "ensures the timeout is isolated to the current fiber" do
        described_class.with(timeout: 10) do
          expect(described_class.current_timeout).to eq(10)
          fiber = Fiber.new do
            expect(described_class.current_timeout).to be_nil
            described_class.with(timeout: 20) do
              expect(described_class.current_timeout).to eq(20)
            end
          end
          fiber.resume
          expect(described_class.current_timeout).to eq(10)
        end
        expect(described_class.current_timeout).to be_nil
      end

      context "with calls within a Thread" do
        it "timeout stack is isolated within the thread" do
          described_class.with(timeout: 10) do
            expect(described_class.current_timeout).to eq(10)
            thread = Thread.new do
              expect(described_class.current_timeout).to be_nil
              described_class.with(timeout: 20) do
                expect(described_class.current_timeout).to eq(20)
              end
            end
            thread.join
            expect(described_class.current_timeout).to eq(10)
          end
          expect(described_class.current_timeout).to be_nil
        end
      end
    end
  end

  describe ".current_timeout" do
    subject(:current_timeout) { described_class.current_timeout }
    context "when no timeout is set" do
      it "returns nil" do
        expect(current_timeout).to be_nil
      end
    end

    context "when a timeout is set" do
      it "returns the timeout" do
        described_class.with(timeout: 10) do
          expect(current_timeout).to eq(10)
        end
      end
    end
  end

  describe "isolation_scope=" do

  end
end

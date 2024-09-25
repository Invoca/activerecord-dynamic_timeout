# frozen_string_literal: true

require "active_record/dynamic_timeout/extensions/base_extension"

RSpec.describe ActiveRecord::DynamicTimeout::BaseExtension do
  before do
    base.instance_variable_set(:@timeout_isolation_scope, nil)
  end

  let(:base) do
    Class.new(ActiveRecord::Base) do
      include ActiveRecord::DynamicTimeout::BaseExtension
      def self.name
        "Base"
      end
    end
  end

  describe ".with_timeout" do
    context "when timeout is an integer" do
      it "sets the timeout" do
        base.with_timeout(10) do
          expect(base.current_timeout_seconds).to eq(10)
        end
      end
    end

    context "when timeout is nil" do
      it "sets the timeout to nil" do
        base.with_timeout(nil) do
          expect(base.current_timeout_seconds).to be_nil
        end
      end
    end

    context "when timeout is a float" do
      it "sets the timeout to the float" do
        base.with_timeout(10.5) do
          expect(base.current_timeout_seconds).to eq(10.5)
        end
      end
    end

    context "when timeout is an ActiveSupport::Duration" do
      it "sets the timeout to the duration" do
        base.with_timeout(10.seconds) do
          expect(base.current_timeout_seconds).to eq(10.seconds)
        end
      end
    end

    context "when timeout is not an integer or nil" do
      it "raises an ArgumentError" do
        expect { base.with_timeout("foo") { } }.to raise_error(ArgumentError, /timeout_seconds must be Numeric or NilClass/)
      end
    end

    context "with_timeout nested calls" do
      it "sets the timeout to the innermost value" do
        base.with_timeout(10) do
          base.with_timeout(20) do
            expect(base.current_timeout_seconds).to eq(20)
          end
          expect(base.current_timeout_seconds).to eq(10)
        end
      end

      context "with_timeout a nil timeout" do
        it "sets the timeout to nil" do
          base.with_timeout(10) do
            base.with_timeout(nil) do
              expect(base.current_timeout_seconds).to be_nil
            end
            expect(base.current_timeout_seconds).to eq(10)
          end
        end
      end
    end

    context "when isolation level is set to Thread" do
      before do
        base.timeout_isolation_scope = Thread
      end

      it "ensures the timeout is isolated to the current thread" do
        base.with_timeout(10) do
          expect(base.current_timeout_seconds).to eq(10)
          thread = Thread.new do
            expect(base.current_timeout_seconds).to be_nil
            base.with_timeout(20) do
              expect(base.current_timeout_seconds).to eq(20)
            end
          end
          thread.join
          expect(base.current_timeout_seconds).to eq(10)
        end
        expect(base.current_timeout_seconds).to be_nil
      end

      context "with_timeout calls within a Fiber" do
        it "has the same timeout within the fiber that is set in the thread" do
          base.with_timeout(10) do
            expect(base.current_timeout_seconds).to eq(10)
            fiber = Fiber.new do
              expect(base.current_timeout_seconds).to eq(10)
              base.with_timeout(20) do
                expect(base.current_timeout_seconds).to eq(20)
              end
            end
            fiber.resume
            expect(base.current_timeout_seconds).to eq(10)
          end
          expect(base.current_timeout_seconds).to be_nil
        end
      end
    end

    context "when isolation level is set to Fiber" do
      before do
        base.timeout_isolation_scope = Fiber
      end

      it "ensures the timeout is isolated to the current fiber" do
        base.with_timeout(10) do
          expect(base.current_timeout_seconds).to eq(10)
          fiber = Fiber.new do
            expect(base.current_timeout_seconds).to be_nil
            base.with_timeout(20) do
              expect(base.current_timeout_seconds).to eq(20)
            end
          end
          fiber.resume
          expect(base.current_timeout_seconds).to eq(10)
        end
        expect(base.current_timeout_seconds).to be_nil
      end

      context "with_timeout calls within a Thread" do
        it "timeout stack is isolated within the thread" do
          base.with_timeout(10) do
            expect(base.current_timeout_seconds).to eq(10)
            thread = Thread.new do
              expect(base.current_timeout_seconds).to be_nil
              base.with_timeout(20) do
                expect(base.current_timeout_seconds).to eq(20)
              end
            end
            thread.join
            expect(base.current_timeout_seconds).to eq(10)
          end
          expect(base.current_timeout_seconds).to be_nil
        end
      end
    end
  end

  describe ".current_timeout_seconds" do
    subject(:current_timeout_seconds) { base.current_timeout_seconds }
    context "when no timeout is set" do
      it "returns nil" do
        expect(current_timeout_seconds).to be_nil
      end
    end

    context "when a timeout is set" do
      it "returns the timeout" do
        base.with_timeout(10) do
          expect(current_timeout_seconds).to eq(10)
        end
      end
    end
  end

  describe "timeout_isolation_scope=" do

  end
end

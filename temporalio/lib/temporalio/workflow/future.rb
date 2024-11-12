# frozen_string_literal: true

require 'temporalio/workflow'

module Temporalio
  module Workflow
    class Future
      def self.any_of(*futures)
        Future.new do
          Workflow.wait_condition(cancellation: nil) { futures.any?(&:done?) }
          futures.find(&:done?).wait
        end
      end

      def self.all_of(*futures)
        Future.new do
          Workflow.wait_condition(cancellation: nil) { futures.all?(&:done?) }
          # Raise on error if any
          futures.find(&:failure?)&.wait
          nil
        end
      end

      def self.try_any_of(*futures)
        Future.new do
          Workflow.wait_condition(cancellation: nil) { futures.any?(&:done?) }
          futures.find(&:done?)
        end
      end

      def self.try_all_of(*futures)
        Future.new do
          Workflow.wait_condition(cancellation: nil) { futures.all?(&:done?) }
          nil
        end
      end

      attr_reader :result, :failure

      def initialize(&block)
        @done = false
        @result = nil
        @failure = nil
        @block_given = block_given?
        return unless block_given?

        @fiber = Fiber.schedule do
          @result = block.call
        rescue Exception => e # rubocop:disable Lint/RescueException
          @failure = e
        ensure
          @done = true
        end
      end

      def done?
        @done
      end

      def result?
        done? && !failure
      end

      def result=(result)
        Kernel.raise 'Cannot set result if block given in constructor' if @block_given
        return if done?

        @result = result
        @done = true
      end

      def failure?
        done? && failure
      end

      def failure=(failure)
        Kernel.raise 'Cannot set result if block given in constructor' if @block_given
        Kernel.raise 'Cannot set nil failure' if failure.nil?
        return if done?

        @failure = failure
        @done = true
      end

      # TODO(cretz): Timeout? Cancellation?
      def wait
        Workflow.wait_condition(cancellation: nil) { done? }
        Kernel.raise failure if failure?

        result
      end

      def wait_no_raise
        Workflow.wait_condition(cancellation: nil) { done? }
        result
      end
    end
  end
end

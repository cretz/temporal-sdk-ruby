# frozen_string_literal: true

module Temporalio
  module Workflow
    class ChildWorkflowHandle
      def initialize
        raise NotImplementedError, 'Cannot instantiate a child handle directly'
      end

      def id
        raise NotImplementedError
      end

      def first_execution_run_id
        raise NotImplementedError
      end

      def result
        raise NotImplementedError
      end

      def signal(signal, *args, cancellation: Workflow.cancellation)
        raise NotImplementedError
      end
    end
  end
end

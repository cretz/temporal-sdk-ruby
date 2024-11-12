# frozen_string_literal: true

require 'temporalio/worker/workflow_executor/ractor'
require 'temporalio/worker/workflow_executor/thread_pool'

module Temporalio
  class Worker
    class WorkflowExecutor
      def initialize
        raise 'Cannot create custom executors'
      end

      def _validate_worker(worker, worker_options)
        raise NotImplementedError
      end

      def _activate(activation, worker_options, &)
        raise NotImplementedError
      end
    end
  end
end

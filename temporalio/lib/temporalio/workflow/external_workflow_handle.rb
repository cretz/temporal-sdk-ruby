# frozen_string_literal: true

require 'temporalio/workflow'

module Temporalio
  module Workflow
    class ExternalWorkflowHandle
      def initialize
        raise NotImplementedError, 'Cannot instantiate an external handle directly'
      end

      def id
        raise NotImplementedError
      end

      def run_id
        raise NotImplementedError
      end

      def signal(signal, *args, cancellation: Workflow.cancellation)
        raise NotImplementedError
      end

      def cancel
        raise NotImplementedError
      end
    end
  end
end

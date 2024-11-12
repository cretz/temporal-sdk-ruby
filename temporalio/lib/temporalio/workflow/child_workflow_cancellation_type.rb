# frozen_string_literal: true

require 'temporalio/internal/bridge/api'

module Temporalio
  module Workflow
    module ChildWorkflowCancellationType
      ABANDON = Internal::Bridge::Api::ChildWorkflow::ChildWorkflowCancellationType::ABANDON
      TRY_CANCEL = Internal::Bridge::Api::ChildWorkflow::ChildWorkflowCancellationType::TRY_CANCEL
      WAIT_CANCELLATION_COMPLETED =
        Internal::Bridge::Api::ChildWorkflow::ChildWorkflowCancellationType::WAIT_CANCELLATION_COMPLETED
      WAIT_CANCELLATION_REQUESTED =
        Internal::Bridge::Api::ChildWorkflow::ChildWorkflowCancellationType::WAIT_CANCELLATION_REQUESTED
    end
  end
end

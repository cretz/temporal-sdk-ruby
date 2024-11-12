# frozen_string_literal: true

require 'temporalio/internal/bridge/api'

module Temporalio
  module Workflow
    module ActivityCancellationType
      TRY_CANCEL = Internal::Bridge::Api::WorkflowCommands::ActivityCancellationType::TRY_CANCEL
      WAIT_CANCELLATION_COMPLETED =
        Internal::Bridge::Api::WorkflowCommands::ActivityCancellationType::WAIT_CANCELLATION_COMPLETED
      ABANDON = Internal::Bridge::Api::WorkflowCommands::ActivityCancellationType::ABANDON
    end
  end
end

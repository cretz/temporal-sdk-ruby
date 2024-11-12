# frozen_string_literal: true

require 'temporalio/internal/bridge/api'

module Temporalio
  module Workflow
    module ParentClosePolicy
      UNSPECIFIED = Internal::Bridge::Api::ChildWorkflow::ParentClosePolicy::PARENT_CLOSE_POLICY_UNSPECIFIED
      TERMINATE = Internal::Bridge::Api::ChildWorkflow::ParentClosePolicy::PARENT_CLOSE_POLICY_TERMINATE
      ABANDON = Internal::Bridge::Api::ChildWorkflow::ParentClosePolicy::PARENT_CLOSE_POLICY_ABANDON
      REQUEST_CANCEL = Internal::Bridge::Api::ChildWorkflow::ParentClosePolicy::PARENT_CLOSE_POLICY_REQUEST_CANCEL
    end
  end
end

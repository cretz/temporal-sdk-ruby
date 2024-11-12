# frozen_string_literal: true

module Temporalio
  module Internal
    module Worker
      class WorkflowInstance
        class HandlerExecution
          attr_reader :name, :update_id, :unfinished_policy

          def initialize(
            name:,
            update_id:,
            unfinished_policy:
          )
            @name = name
            @update_id = update_id
            @unfinished_policy = unfinished_policy
          end
        end
      end
    end
  end
end

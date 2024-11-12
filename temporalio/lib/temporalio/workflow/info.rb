# frozen_string_literal: true

module Temporalio
  module Workflow
    Info = Struct.new(
      :attempt,
      :continued_run_id,
      :cron_schedule,
      :execution_timeout,
      :last_failure,
      :last_result,
      :namespace,
      :parent,
      :retry_policy,
      :run_id,
      :run_timeout,
      :start_time,
      :task_queue,
      :task_timeout,
      :workflow_id,
      :workflow_type,
      keyword_init: true
    )

    class Info
      ParentInfo = Struct.new(
        :namespace,
        :run_id,
        :workflow_id
      )
    end
  end
end

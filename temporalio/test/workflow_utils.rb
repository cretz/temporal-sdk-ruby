# frozen_string_literal: true

require 'securerandom'
require 'temporalio/client'
require 'temporalio/testing'
require 'temporalio/worker'
require 'temporalio/workflow'
require 'test'

module WorkflowUtils
  def execute_workflow(
    workflow,
    *args,
    activities: [],
    more_workflows: [],
    search_attributes: nil,
    memo: nil,
    retry_policy: nil,
    workflow_failure_exception_types: [],
    max_cached_workflows: 1000,
    logger: nil,
    client: env.client,
    workflow_payload_codec_thread_pool: nil
  )
    worker = Temporalio::Worker.new(
      client:,
      task_queue: "tq-#{SecureRandom.uuid}",
      activities:,
      workflows: [workflow] + more_workflows,
      # TODO(cretz): Ractor support not currently working
      workflow_executor: Temporalio::Worker::WorkflowExecutor::ThreadPool.default,
      workflow_failure_exception_types:,
      max_cached_workflows:,
      logger: logger || client.options.logger,
      workflow_payload_codec_thread_pool:
    )
    worker.run do
      handle = client.start_workflow(
        workflow,
        *args,
        id: "wf-#{SecureRandom.uuid}",
        task_queue: worker.task_queue,
        search_attributes:,
        memo:,
        retry_policy:
      )
      if block_given?
        yield handle, worker
      else
        handle.result
      end
    end
  end

  def assert_eventually_task_fail(handle:, message_contains: nil)
    assert_eventually do
      event = handle.fetch_history_events.find(&:workflow_task_failed_event_attributes)
      refute_nil event
      assert_includes(event.workflow_task_failed_event_attributes.failure.message, message_contains) if message_contains
      event
    end
  end
end

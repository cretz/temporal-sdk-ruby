# frozen_string_literal: true

require 'temporalio/workflow/activity_cancellation_type'
require 'temporalio/workflow/child_workflow_cancellation_type'
require 'temporalio/workflow/child_workflow_handle'
require 'temporalio/workflow/definition'
require 'temporalio/workflow/future'
require 'temporalio/workflow/handler_unfinished_policy'
require 'temporalio/workflow/info'
require 'temporalio/workflow/parent_close_policy'
require 'temporalio/workflow/update_info'
require 'timeout'

module Temporalio
  module Workflow
    def self.cancellation
      _current.cancellation
    end

    def self.continue_as_new_suggested
      _current.continue_as_new_suggested
    end

    def self.current_history_length
      _current.current_history_length
    end

    def self.current_history_size
      _current.current_history_size
    end

    def self.current_update_info
      _current.current_update_info
    end

    def self.execute_activity(
      activity,
      *args,
      task_queue: nil,
      schedule_to_close_timeout: nil,
      schedule_to_start_timeout: nil,
      start_to_close_timeout: nil,
      heartbeat_timeout: nil,
      retry_policy: nil,
      cancellation: Workflow.cancellation,
      cancellation_type: ActivityCancellationType::TRY_CANCEL,
      activity_id: nil,
      disable_eager_execution: false
    )
      _current.execute_activity(
        activity, *args,
        task_queue:, schedule_to_close_timeout:, schedule_to_start_timeout:, start_to_close_timeout:,
        heartbeat_timeout:, retry_policy:, cancellation:, cancellation_type:, activity_id:, disable_eager_execution:
      )
    end

    def self.execute_child_workflow(
      workflow,
      *args,
      id: random.uuid,
      task_queue: info.task_queue,
      cancellation: Workflow.cancellation,
      cancellation_type: ChildWorkflowCancellationType::WAIT_CANCELLATION_COMPLETED,
      parent_close_policy: ParentClosePolicy::TERMINATE,
      execution_timeout: nil,
      run_timeout: nil,
      task_timeout: nil,
      id_reuse_policy: WorkflowIDReusePolicy::ALLOW_DUPLICATE,
      retry_policy: nil,
      cron_schedule: nil,
      memo: nil,
      search_attributes: nil
    )
      start_child_workflow(
        workflow, *args,
        id:, task_queue:, cancellation:, cancellation_type:, parent_close_policy:, execution_timeout:, run_timeout:,
        task_timeout:, id_reuse_policy:, retry_policy:, cron_schedule:, memo:, search_attributes:
      ).result
    end

    def self.execute_local_activity(
      activity,
      *args,
      schedule_to_close_timeout: nil,
      schedule_to_start_timeout: nil,
      start_to_close_timeout: nil,
      retry_policy: nil,
      local_retry_threshold: nil,
      cancellation: Workflow.cancellation,
      cancellation_type: ActivityCancellationType::TRY_CANCEL,
      activity_id: nil
    )
      _current.execute_local_activity(
        activity, *args,
        schedule_to_close_timeout:, schedule_to_start_timeout:, start_to_close_timeout:,
        retry_policy:, local_retry_threshold:, cancellation:, cancellation_type:, activity_id:
      )
    end

    def self.in_workflow?
      _current_or_nil != nil
    end

    def self.info
      _current.info
    end

    def self.logger
      _current.logger
    end

    def self.memo
      _current.memo
    end

    def self.payload_converter
      _current.payload_converter
    end

    def self.random
      _current.random
    end

    def self.query_handlers
      _current.query_handlers
    end

    def self.search_attributes
      _current.search_attributes
    end

    def self.signal_handlers
      _current.signal_handlers
    end

    def self.sleep(duration, summary: nil, cancellation: Workflow.cancellation)
      _current.sleep(duration, summary:, cancellation:)
    end

    def self.timeout(
      duration,
      exception_class = Timeout::Error,
      message = 'execution expired',
      summary: 'Timeout timer',
      &
    )
      _current.timeout(duration, exception_class, message, summary:, &)
    end

    def self.start_child_workflow(
      workflow,
      *args,
      id: random.uuid,
      task_queue: info.task_queue,
      cancellation: Workflow.cancellation,
      cancellation_type: ChildWorkflowCancellationType::WAIT_CANCELLATION_COMPLETED,
      parent_close_policy: ParentClosePolicy::TERMINATE,
      execution_timeout: nil,
      run_timeout: nil,
      task_timeout: nil,
      id_reuse_policy: WorkflowIDReusePolicy::ALLOW_DUPLICATE,
      retry_policy: nil,
      cron_schedule: nil,
      memo: nil,
      search_attributes: nil
    )
      _current.start_child_workflow(
        workflow, *args,
        id:, task_queue:, cancellation:, cancellation_type:, parent_close_policy:, execution_timeout:, run_timeout:,
        task_timeout:, id_reuse_policy:, retry_policy:, cron_schedule:, memo:, search_attributes:
      )
    end

    def self.update_handlers
      _current.update_handlers
    end

    def self.upsert_memo(hash)
      _current.upsert_memo(hash)
    end

    def self.upsert_search_attributes(*updates)
      _current.upsert_search_attributes(*updates)
    end

    # TODO(cretz): Timeout?
    def self.wait_condition(cancellation: Workflow.cancellation, &)
      raise 'Block required' unless block_given?

      _current.wait_condition(cancellation:, &)
    end

    def self._current
      current = _current_or_nil
      raise Error, 'Not in workflow environment' if current.nil?

      current
    end

    def self._current_or_nil
      # We choose to use Fiber.scheduler instead of Fiber.current_scheduler here because the constructor of the class is
      # not scheduled on this scheduler and so current_scheduler is nil during class construction.
      sched = Fiber.scheduler
      return sched.context if sched.is_a?(Internal::Worker::WorkflowInstance::Scheduler)

      nil
    end

    class Unsafe
      def self.replaying?
        Workflow._current.replaying?
      end

      def self.illegal_call_tracing_disabled(&)
        Workflow._current.illegal_call_tracing_disabled(&)
      end
    end

    class ContinueAsNewError < Error
      attr_accessor :args, :workflow, :task_queue, :run_timeout, :task_timeout,
                    :retry_policy, :memo, :search_attributes, :headers

      def initialize(
        *args,
        workflow: nil,
        task_queue: nil,
        run_timeout: nil,
        task_timeout: nil,
        retry_policy: nil,
        memo: nil,
        search_attributes: nil,
        headers: {}
      )
        @args = args
        @workflow = workflow
        @task_queue = task_queue
        @run_timeout = run_timeout
        @task_timeout = task_timeout
        @retry_policy = retry_policy
        @memo = memo
        @search_attributes = search_attributes
        @headers = headers
        Workflow._current.initialize_continue_as_new_error(self)
      end
    end

    class NondeterminismError < Error; end
  end
end

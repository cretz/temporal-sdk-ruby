# frozen_string_literal: true

require 'net/http'
require 'temporalio/client'
require 'temporalio/testing'
require 'temporalio/worker'
require 'temporalio/workflow'
require 'test'
require 'timeout'
require 'workflow_utils'

class WorkerWorkflowTest < Test
  include WorkflowUtils

  class SimpleWorkflow < Temporalio::Workflow::Definition
    def execute(name)
      "Hello, #{name}!"
    end
  end

  def test_simple
    assert_equal 'Hello, Temporal!', execute_workflow(SimpleWorkflow, 'Temporal')
  end

  class IllegalCallsWorkflow < Temporalio::Workflow::Definition
    def execute(scenario)
      case scenario.to_sym
      when :argv
        ARGV
      when :date_new
        Date.new
      when :date_today
        Date.today
      when :env
        ENV.fetch('foo', nil)
      when :file_directory
        File.directory?('.')
      when :file_read
        File.read('Rakefile')
      when :http_get
        Net::HTTP.get('https://example.com')
      when :kernel_rand
        Kernel.rand
      when :random_new
        Random.new.rand
      when :thread_new
        Thread.new { 'wut' }.join
      when :time_new
        Time.new
      when :time_now
        Time.now
      else
        raise NotImplementedError
      end
    end
  end

  def test_illegal_calls
    exec = lambda do |scenario, method|
      execute_workflow(IllegalCallsWorkflow, scenario) do |handle|
        if method
          assert_eventually_task_fail(handle:, message_contains: "Cannot access #{method} from inside a workflow")
        else
          handle.result
        end
      end
    end

    exec.call(:argv, nil) # Cannot reasonably prevent
    exec.call(:date_new, 'Date initialize')
    exec.call(:date_today, 'Date today')
    exec.call(:env, nil) # Cannot reasonably prevent
    exec.call(:file_directory, 'File directory?')
    exec.call(:file_read, 'IO read')
    exec.call(:http_get, 'Net::HTTP get')
    exec.call(:kernel_rand, 'Kernel rand')
    exec.call(:random_new, 'Random::Base initialize')
    exec.call(:thread_new, 'Thread new')
    exec.call(:time_new, 'Time initialize')
    exec.call(:time_now, 'Time now')
  end

  class WorkflowInitWorkflow < Temporalio::Workflow::Definition
    workflow_init
    def initialize(arg1, arg2)
      @args = [arg1, arg2]
    end

    def execute(_ignore1, _ignore2)
      @args
    end
  end

  def test_workflow_init
    assert_equal ['foo', 123], execute_workflow(WorkflowInitWorkflow, 'foo', 123)
  end

  class RawValueWorkflow < Temporalio::Workflow::Definition
    workflow_raw_args

    workflow_init
    def initialize(arg1, arg2)
      raise 'Expected raw' unless arg1.is_a?(Temporalio::Converters::RawValue)
      raise 'Expected raw' unless arg2.is_a?(Temporalio::Converters::RawValue)
    end

    def execute(arg1, arg2)
      raise 'Expected raw' unless arg1.is_a?(Temporalio::Converters::RawValue)
      raise 'Bad value' unless Temporalio::Workflow.payload_converter.from_payload(arg1.payload) == 'foo'
      raise 'Expected raw' unless arg2.is_a?(Temporalio::Converters::RawValue)
      raise 'Bad value' unless Temporalio::Workflow.payload_converter.from_payload(arg2.payload) == 123

      Temporalio::Converters::RawValue.new(
        Temporalio::Api::Common::V1::Payload.new(
          metadata: { 'encoding' => 'json/plain' },
          data: '{"foo": "bar"}'.b
        )
      )
    end
  end

  def test_raw_value
    assert_equal({ 'foo' => 'bar' }, execute_workflow(RawValueWorkflow, 'foo', 123))
  end

  class ArgCountWorkflow < Temporalio::Workflow::Definition
    def execute(arg1, arg2)
      [arg1, arg2]
    end
  end

  def test_arg_count
    # Extra arguments are allowed and just discarded, too few are not allowed
    execute_workflow(ArgCountWorkflow) do |handle|
      assert_eventually_task_fail(handle:, message_contains: 'wrong number of arguments (given 0, expected 2)')
    end
    assert_equal %w[one two], execute_workflow(ArgCountWorkflow, 'one', 'two')
    assert_equal %w[three four], execute_workflow(ArgCountWorkflow, 'three', 'four', 'five')
  end

  class InfoWorkflow < Temporalio::Workflow::Definition
    def execute
      Temporalio::Workflow.info.to_h
    end
  end

  def test_info
    execute_workflow(InfoWorkflow) do |handle, worker|
      info = handle.result
      assert_equal 1, info['attempt']
      assert_nil info.fetch('continued_run_id')
      assert_nil info.fetch('cron_schedule')
      assert_nil info.fetch('execution_timeout')
      assert_nil info.fetch('last_failure')
      assert_nil info.fetch('last_result')
      assert_equal env.client.namespace, info['namespace']
      assert_nil info.fetch('parent')
      assert_nil info.fetch('retry_policy')
      assert_equal handle.result_run_id, info['run_id']
      assert_nil info.fetch('run_timeout')
      refute_nil info['start_time']
      assert_equal worker.task_queue, info['task_queue']
      assert_equal 10.0, info['task_timeout']
      assert_equal handle.id, info['workflow_id']
      assert_equal 'InfoWorkflow', info['workflow_type']
    end
  end

  class HistoryInfoWorkflow < Temporalio::Workflow::Definition
    def execute
      # Start 30 10ms timers and wait on them all
      Temporalio::Workflow::Future.all_of(
        *30.times.map { Temporalio::Workflow::Future.new { sleep(0.1) } }
      ).wait

      [
        Temporalio::Workflow.continue_as_new_suggested,
        Temporalio::Workflow.current_history_length,
        Temporalio::Workflow.current_history_size
      ]
    end
  end

  def test_history_info
    can_suggested, hist_len, hist_size = execute_workflow(HistoryInfoWorkflow)
    refute can_suggested
    assert hist_len > 60
    assert hist_size > 1500
  end

  class WaitConditionWorkflow < Temporalio::Workflow::Definition
    workflow_query_attr_reader :waiting

    def execute(scenario)
      case scenario.to_sym
      when :stages
        @stages = ['one']
        Temporalio::Workflow::Future.new do
          Temporalio::Workflow.wait_condition { @stages.last != 'one' }
          raise 'Invalid stage' unless @stages.last == 'two'

          @stages << 'three'
        end
        Temporalio::Workflow::Future.new do
          Temporalio::Workflow.wait_condition { !@stages.empty? }
          raise 'Invalid stage' unless @stages.last == 'one'

          @stages << 'two'
        end
        Temporalio::Workflow::Future.new do
          Temporalio::Workflow.wait_condition { !@stages.empty? }
          raise 'Invalid stage' unless @stages.last == 'three'

          @stages << 'four'
        end
        Temporalio::Workflow.wait_condition { @stages.last == 'four' }
        @stages
      when :workflow_cancel
        @waiting = true
        Temporalio::Workflow.wait_condition { false }
      when :timeout
        Timeout.timeout(0.1) do
          Temporalio::Workflow.wait_condition { false }
        end
      when :manual_cancel
        my_cancel, my_cancel_proc = Temporalio::Cancellation.new
        Temporalio::Workflow::Future.new do
          sleep(0.1)
          my_cancel_proc.call(reason: 'my cancel reason')
        end
        Temporalio::Workflow.wait_condition(cancellation: my_cancel) { false }
      when :manual_cancel_before_wait
        my_cancel, my_cancel_proc = Temporalio::Cancellation.new
        my_cancel_proc.call(reason: 'my cancel reason')
        Temporalio::Workflow.wait_condition(cancellation: my_cancel) { false }
      else
        raise NotImplementedError
      end
    end
  end

  def test_wait_condition
    assert_equal %w[one two three four], execute_workflow(WaitConditionWorkflow, :stages)

    execute_workflow(WaitConditionWorkflow, :workflow_cancel) do |handle|
      assert_eventually { assert handle.query(WaitConditionWorkflow.waiting) }
      handle.cancel
      err = assert_raises(Temporalio::Error::WorkflowFailedError) { handle.result }
      assert_equal 'Workflow execution canceled', err.message
      assert_instance_of Temporalio::Error::CanceledError, err.cause
    end

    err = assert_raises(Temporalio::Error::WorkflowFailedError) { execute_workflow(WaitConditionWorkflow, :timeout) }
    assert_equal 'execution expired', err.cause.message

    err = assert_raises(Temporalio::Error::WorkflowFailedError) do
      execute_workflow(WaitConditionWorkflow, :manual_cancel)
    end
    assert_equal 'Workflow execution failed', err.message
    assert_instance_of Temporalio::Error::CanceledError, err.cause
    assert_equal 'my cancel reason', err.cause.message

    err = assert_raises(Temporalio::Error::WorkflowFailedError) do
      execute_workflow(WaitConditionWorkflow, :manual_cancel_before_wait)
    end
    assert_equal 'Workflow execution failed', err.message
    assert_instance_of Temporalio::Error::CanceledError, err.cause
    assert_equal 'my cancel reason', err.cause.message
  end

  class TimerWorkflow < Temporalio::Workflow::Definition
    workflow_query_attr_reader :waiting

    def execute(scenario)
      case scenario.to_sym
      when :sleep_stdlib
        sleep(0.11)
      when :sleep_workflow
        Temporalio::Workflow.sleep(0.12, summary: 'my summary')
      when :sleep_stdlib_workflow_cancel
        sleep(1000)
      when :sleep_workflow_cancel
        Temporalio::Workflow.sleep(1000)
      when :sleep_explicit_cancel
        my_cancel, my_cancel_proc = Temporalio::Cancellation.new
        Temporalio::Workflow::Future.new do
          sleep(0.1)
          my_cancel_proc.call(reason: 'my cancel reason')
        end
        Temporalio::Workflow.sleep(1000, cancellation: my_cancel)
      when :sleep_cancel_before_start
        my_cancel, my_cancel_proc = Temporalio::Cancellation.new
        my_cancel_proc.call(reason: 'my cancel reason')
        Temporalio::Workflow.sleep(1000, cancellation: my_cancel)
      when :timeout_stdlib
        Timeout.timeout(0.16) do
          Temporalio::Workflow.wait_condition { false }
        end
      when :timeout_workflow
        Temporalio::Workflow.timeout(0.17) do
          Temporalio::Workflow.wait_condition { false }
        end
      when :timeout_custom_info
        Temporalio::Workflow.timeout(0.18, Temporalio::Error::ApplicationError, 'some message') do
          Temporalio::Workflow.wait_condition { false }
        end
      when :timeout_infinite
        @waiting = true
        Temporalio::Workflow.timeout(nil) do
          Temporalio::Workflow.wait_condition { @interrupt }
        end
      when :timeout_negative
        Temporalio::Workflow.timeout(-1) do
          Temporalio::Workflow.wait_condition { false }
        end
      when :timeout_workflow_cancel
        Timeout.timeout(1000) do
          Temporalio::Workflow.wait_condition { false }
        end
      when :timeout_not_reached
        Timeout.timeout(1000) do
          Temporalio::Workflow.wait_condition { @return_value }
        end
        @waiting = true
        Temporalio::Workflow.wait_condition { @interrupt }
        @return_value
      else
        raise NotImplementedError
      end
    end

    workflow_signal
    def interrupt
      @interrupt = true
    end

    workflow_signal
    def return_value(value)
      @return_value = value
    end
  end

  def test_timer
    event = execute_workflow(TimerWorkflow, :sleep_stdlib) do |handle|
      handle.result
      handle.fetch_history_events.find(&:timer_started_event_attributes)
    end
    assert_equal 0.11, event.timer_started_event_attributes.start_to_fire_timeout.to_f

    event = execute_workflow(TimerWorkflow, :sleep_workflow) do |handle|
      handle.result
      handle.fetch_history_events.find(&:timer_started_event_attributes)
    end
    assert_equal 0.12, event.timer_started_event_attributes.start_to_fire_timeout.to_f
    # TODO(cretz): Assert summary

    execute_workflow(TimerWorkflow, :sleep_stdlib_workflow_cancel) do |handle|
      assert_eventually { assert handle.fetch_history_events.any?(&:timer_started_event_attributes) }
      handle.cancel
      err = assert_raises(Temporalio::Error::WorkflowFailedError) { handle.result }
      assert_instance_of Temporalio::Error::CanceledError, err.cause
    end

    execute_workflow(TimerWorkflow, :sleep_workflow_cancel) do |handle|
      assert_eventually { assert handle.fetch_history_events.any?(&:timer_started_event_attributes) }
      handle.cancel
      err = assert_raises(Temporalio::Error::WorkflowFailedError) { handle.result }
      assert_instance_of Temporalio::Error::CanceledError, err.cause
    end

    err = assert_raises(Temporalio::Error::WorkflowFailedError) do
      execute_workflow(TimerWorkflow, :sleep_explicit_cancel)
    end
    assert_equal 'Workflow execution failed', err.message
    assert_instance_of Temporalio::Error::CanceledError, err.cause
    assert_equal 'my cancel reason', err.cause.message

    err = assert_raises(Temporalio::Error::WorkflowFailedError) do
      execute_workflow(TimerWorkflow, :sleep_cancel_before_start)
    end
    assert_equal 'Workflow execution failed', err.message
    assert_instance_of Temporalio::Error::CanceledError, err.cause
    assert_equal 'my cancel reason', err.cause.message

    err = assert_raises(Temporalio::Error::WorkflowFailedError) { execute_workflow(TimerWorkflow, :timeout_stdlib) }
    assert_instance_of Temporalio::Error::ApplicationError, err.cause
    assert_equal 'execution expired', err.cause.message
    assert_equal 'Timeout::Error', err.cause.type

    err = assert_raises(Temporalio::Error::WorkflowFailedError) { execute_workflow(TimerWorkflow, :timeout_workflow) }
    assert_instance_of Temporalio::Error::ApplicationError, err.cause
    assert_equal 'execution expired', err.cause.message
    assert_equal 'Timeout::Error', err.cause.type

    err = assert_raises(Temporalio::Error::WorkflowFailedError) do
      execute_workflow(TimerWorkflow, :timeout_custom_info)
    end
    assert_instance_of Temporalio::Error::ApplicationError, err.cause
    assert_equal 'some message', err.cause.message
    assert_nil err.cause.type

    execute_workflow(TimerWorkflow, :timeout_infinite) do |handle|
      assert_eventually { assert handle.query(TimerWorkflow.waiting) }
      handle.signal(TimerWorkflow.interrupt)
      handle.result
      refute handle.fetch_history_events.any?(&:timer_started_event_attributes)
    end

    execute_workflow(TimerWorkflow, :timeout_negative) do |handle|
      assert_eventually_task_fail(handle:, message_contains: 'Sleep duration cannot be less than 0')
    end

    execute_workflow(TimerWorkflow, :timeout_workflow_cancel) do |handle|
      assert_eventually { assert handle.fetch_history_events.any?(&:timer_started_event_attributes) }
      handle.cancel
      err = assert_raises(Temporalio::Error::WorkflowFailedError) { handle.result }
      assert_instance_of Temporalio::Error::CanceledError, err.cause
    end

    execute_workflow(TimerWorkflow, :timeout_not_reached) do |handle|
      assert_eventually { assert handle.fetch_history_events.any?(&:timer_started_event_attributes) }
      handle.signal(TimerWorkflow.return_value, 'some value')
      assert_eventually { assert handle.query(TimerWorkflow.waiting) }
      assert_eventually { assert handle.fetch_history_events.any?(&:timer_canceled_event_attributes) }
      handle.signal(TimerWorkflow.interrupt)
      assert_equal 'some value', handle.result
    end
  end

  class SearchAttributeMemoWorkflow < Temporalio::Workflow::Definition
    def execute(scenario)
      case scenario.to_sym
      when :search_attributes
        # Collect original, upsert (update one, delete another), collect updated
        orig = Temporalio::Workflow.search_attributes.to_h.transform_keys(&:name)
        Temporalio::Workflow.upsert_search_attributes(
          Test::ATTR_KEY_TEXT.value_set('another-text'),
          Test::ATTR_KEY_KEYWORD.value_unset
        )
        updated = Temporalio::Workflow.search_attributes.to_h.transform_keys(&:name)
        { orig:, updated: }
      when :memo
        # Collect original, upsert (update one, delete another), collect updated
        orig = Temporalio::Workflow.memo.dup
        Temporalio::Workflow.upsert_memo({ key1: 'new-val1', key2: nil })
        updated = Temporalio::Workflow.memo.dup
        { orig:, updated: }
      else
        raise NotImplementedError
      end
    end
  end

  def test_search_attributes_memo
    env.ensure_common_search_attribute_keys

    execute_workflow(
      SearchAttributeMemoWorkflow,
      :search_attributes,
      search_attributes: Temporalio::SearchAttributes.new(
        { ATTR_KEY_TEXT => 'some-text', ATTR_KEY_KEYWORD => 'some-keyword', ATTR_KEY_INTEGER => 123 }
      )
    ) do |handle|
      result = handle.result

      # Check result attrs
      assert_equal 'some-text', result['orig'][ATTR_KEY_TEXT.name]
      assert_equal 'some-keyword', result['orig'][ATTR_KEY_KEYWORD.name]
      assert_equal 123, result['orig'][ATTR_KEY_INTEGER.name]
      assert_equal 'another-text', result['updated'][ATTR_KEY_TEXT.name]
      assert_nil result['updated'][ATTR_KEY_KEYWORD.name]
      assert_equal 123, result['updated'][ATTR_KEY_INTEGER.name]

      # Check describe
      desc = handle.describe
      assert_equal 'another-text', desc.search_attributes[ATTR_KEY_TEXT]
      assert_nil desc.search_attributes[ATTR_KEY_KEYWORD]
      assert_equal 123, desc.search_attributes[ATTR_KEY_INTEGER]
    end

    execute_workflow(
      SearchAttributeMemoWorkflow,
      :memo,
      memo: { key1: 'val1', key2: 'val2', key3: 'val3' }
    ) do |handle|
      result = handle.result

      # Check result attrs
      assert_equal({ 'key1' => 'val1', 'key2' => 'val2', 'key3' => 'val3' }, result['orig'])
      assert_equal({ 'key1' => 'new-val1', 'key3' => 'val3' }, result['updated'])

      # Check describe
      assert_equal({ 'key1' => 'new-val1', 'key3' => 'val3' }, handle.describe.memo)
    end
  end

  class ContinueAsNewWorkflow < Temporalio::Workflow::Definition
    def execute(past_run_ids)
      raise 'Incorrect memo' unless Temporalio::Workflow.memo['past_run_id_count'] == past_run_ids.size
      unless Temporalio::Workflow.info.retry_policy.max_attempts == past_run_ids.size + 1000
        raise 'Incorrect retry policy'
      end

      # CAN until 5 run IDs, updating memo and retry policy on the way
      return past_run_ids if past_run_ids.size == 5

      past_run_ids << Temporalio::Workflow.info.continued_run_id if Temporalio::Workflow.info.continued_run_id
      raise Temporalio::Workflow::ContinueAsNewError.new(
        past_run_ids,
        memo: { past_run_id_count: past_run_ids.size },
        retry_policy: Temporalio::RetryPolicy.new(max_attempts: past_run_ids.size + 1000)
      )
    end
  end

  def test_continue_as_new
    execute_workflow(
      ContinueAsNewWorkflow,
      [],
      # Set initial memo and retry policy, which we expect the workflow will update in CAN
      memo: { past_run_id_count: 0 },
      retry_policy: Temporalio::RetryPolicy.new(max_attempts: 1000)
    ) do |handle|
      result = handle.result
      assert_equal 5, result.size
      assert_equal handle.result_run_id, result.first
    end
  end

  class DeadlockWorkflow < Temporalio::Workflow::Definition
    def execute
      loop do
        # Do nothing
      end
    end
  end

  def test_deadlock
    # TODO(cretz): Do we need more tests? This attempts to interrupt the workflow via a raise on the thread, but do we
    # need to concern ourselves with what happens if that's accidentally swallowed?
    # TODO(cretz): Decrease deadlock detection timeout to make test faster? It is 4s now because shutdown waits on
    # second task.
    execute_workflow(DeadlockWorkflow) do |handle|
      assert_eventually_task_fail(handle:, message_contains: 'Potential deadlock detected')
    end
  end

  class StackTraceWorkflow < Temporalio::Workflow::Definition
    workflow_query_attr_reader :expected_traces

    def initialize
      @expected_traces = []
    end

    def execute
      # Wait forever two coroutines deep
      Temporalio::Workflow::Future.new do
        Temporalio::Workflow::Future.new do
          @expected_traces << ["#{__FILE__}:#{__LINE__ + 1}"]
          Temporalio::Workflow.wait_condition { false }
        end
      end

      # Inside a coroutine and timeout, execute an activity forever
      Temporalio::Workflow::Future.new do
        Timeout.timeout(nil) do
          @expected_traces << ["#{__FILE__}:#{__LINE__ + 1}", "#{__FILE__}:#{__LINE__ - 1}"]
          Temporalio::Workflow.execute_activity('does-not-exist',
                                                task_queue: 'does-not-exist',
                                                start_to_close_timeout: 1000)
        end
      end

      # Wait forever inside a workflow timeout
      Temporalio::Workflow.timeout(nil) do
        @expected_traces << ["#{__FILE__}:#{__LINE__ + 1}", "#{__FILE__}:#{__LINE__ - 1}"]
        Temporalio::Workflow.wait_condition { false }
      end
    end

    workflow_signal
    def wait_signal
      added_trace = ["#{__FILE__}:#{__LINE__ + 2}"]
      @expected_traces << added_trace
      Temporalio::Workflow.wait_condition { @resume_waited_signal }
      @expected_traces.delete(added_trace)
    end

    workflow_update
    def wait_update
      do_recursive_thing(times_remaining: 5, lines: ["#{__FILE__}:#{__LINE__}"])
    end

    def do_recursive_thing(times_remaining:, lines:)
      unless times_remaining.zero?
        do_recursive_thing(times_remaining: times_remaining - 1, lines: lines << "#{__FILE__}:#{__LINE__}")
      end
      @expected_traces << (lines << "#{__FILE__}:#{__LINE__ + 1}")
      Temporalio::Workflow.wait_condition { false }
    end

    workflow_signal
    def resume_waited_signal
      @resume_waited_signal = true
    end
  end

  def test_stack_trace
    execute_workflow(StackTraceWorkflow) do |handle|
      # Start a signal and an update
      handle.signal(StackTraceWorkflow.wait_signal)
      handle.start_update(StackTraceWorkflow.wait_update,
                          wait_for_stage: Temporalio::Client::WorkflowUpdateWaitStage::ACCEPTED)
      assert_expected_traces = lambda do
        actual_traces = handle.query('__stack_trace').split("\n\n").map do |lines|
          # Trim off non-this-class things and ":in ..."
          lines.split("\n").select { |line| line.include?('worker_workflow_test') }.map do |line|
            line, = line.partition(':in')
            line
          end.sort
        end.sort
        expected_traces = handle.query(StackTraceWorkflow.expected_traces).map(&:sort).sort
        assert_equal expected_traces, actual_traces
      end

      # Wait for there to be 5 expected traces and confirm proper trace
      assert_eventually { assert_equal 5, handle.query(StackTraceWorkflow.expected_traces).size }
      assert_expected_traces.call

      # Now complete the waited handle and confirm again
      handle.signal(StackTraceWorkflow.resume_waited_signal)
      assert_equal 4, handle.query(StackTraceWorkflow.expected_traces).size
      assert_expected_traces.call
    end
  end

  class TaskFailureError1 < StandardError; end
  class TaskFailureError2 < StandardError; end
  class TaskFailureError3 < StandardError; end
  class TaskFailureError4 < TaskFailureError3; end

  class TaskFailureWorkflow < Temporalio::Workflow::Definition
    workflow_failure_exception_type TaskFailureError2, TaskFailureError3

    def execute(arg)
      case arg
      when 1
        raise TaskFailureError1, 'one'
      when 2
        raise TaskFailureError2, 'two'
      when 3
        raise TaskFailureError3, 'three'
      when 4
        raise TaskFailureError4, 'four'
      when 'arg'
        raise ArgumentError, 'arg'
      else
        raise NotImplementedError
      end
    end
  end

  def test_task_failure
    # Normally just fails task
    execute_workflow(TaskFailureWorkflow, 1) do |handle|
      assert_eventually_task_fail(handle:, message_contains: 'one')
    end

    # Fails workflow when configured on worker
    err = assert_raises(Temporalio::Error::WorkflowFailedError) do
      execute_workflow(TaskFailureWorkflow, 1, workflow_failure_exception_types: [TaskFailureError1])
    end
    assert_equal 'one', err.cause.message
    assert_equal 'WorkerWorkflowTest::TaskFailureError1', err.cause.type

    # Fails workflow when configured on workflow, including inherited
    err = assert_raises(Temporalio::Error::WorkflowFailedError) { execute_workflow(TaskFailureWorkflow, 2) }
    assert_equal 'two', err.cause.message
    assert_equal 'WorkerWorkflowTest::TaskFailureError2', err.cause.type
    err = assert_raises(Temporalio::Error::WorkflowFailedError) { execute_workflow(TaskFailureWorkflow, 4) }
    assert_equal 'four', err.cause.message
    assert_equal 'WorkerWorkflowTest::TaskFailureError4', err.cause.type

    # Also supports stdlib errors
    err = assert_raises(Temporalio::Error::WorkflowFailedError) do
      execute_workflow(TaskFailureWorkflow, 'arg', workflow_failure_exception_types: [ArgumentError])
    end
    assert_equal 'arg', err.cause.message
    assert_equal 'ArgumentError', err.cause.type
  end

  class NonDeterminismErrorWorkflow < Temporalio::Workflow::Definition
    workflow_query_attr_reader :waiting

    def execute
      # Do a timer only on non-replay
      sleep(0.01) unless Temporalio::Workflow::Unsafe.replaying?
      Temporalio::Workflow.wait_condition { @finish }
    end

    workflow_signal
    def finish
      @finish = true
    end
  end

  class NonDeterminismErrorSpecificAsFailureWorkflow < NonDeterminismErrorWorkflow
    workflow_failure_exception_type Temporalio::Workflow::NondeterminismError
  end

  class NonDeterminismErrorGenericAsFailureWorkflow < NonDeterminismErrorWorkflow
    workflow_failure_exception_type StandardError
  end

  def test_non_determinism_error
    # Task failure by default
    execute_workflow(NonDeterminismErrorWorkflow, max_cached_workflows: 0) do |handle|
      assert_eventually { assert handle.fetch_history_events.any?(&:workflow_task_completed_event_attributes) }
      handle.signal(NonDeterminismErrorWorkflow.finish)
      assert_eventually_task_fail(handle:, message_contains: 'Nondeterminism')
    end

    # Specifically set on worker turns to failure
    execute_workflow(NonDeterminismErrorWorkflow,
                     max_cached_workflows: 0,
                     workflow_failure_exception_types: [Temporalio::Workflow::NondeterminismError]) do |handle|
      assert_eventually { assert handle.fetch_history_events.any?(&:workflow_task_completed_event_attributes) }
      handle.signal(NonDeterminismErrorWorkflow.finish)
      err = assert_raises(Temporalio::Error::WorkflowFailedError) { handle.result }
      assert_includes err.cause.message, 'Nondeterminism'
    end

    # Generically set on worker turns to failure
    execute_workflow(NonDeterminismErrorWorkflow,
                     max_cached_workflows: 0,
                     workflow_failure_exception_types: [StandardError]) do |handle|
      assert_eventually { assert handle.fetch_history_events.any?(&:workflow_task_completed_event_attributes) }
      handle.signal(NonDeterminismErrorWorkflow.finish)
      err = assert_raises(Temporalio::Error::WorkflowFailedError) { handle.result }
      assert_includes err.cause.message, 'Nondeterminism'
    end

    # Specifically set on workflow turns to failure
    execute_workflow(NonDeterminismErrorSpecificAsFailureWorkflow, max_cached_workflows: 0) do |handle|
      assert_eventually { assert handle.fetch_history_events.any?(&:workflow_task_completed_event_attributes) }
      handle.signal(NonDeterminismErrorSpecificAsFailureWorkflow.finish)
      err = assert_raises(Temporalio::Error::WorkflowFailedError) { handle.result }
      assert_includes err.cause.message, 'Nondeterminism'
    end

    # Generically set on workflow turns to failure
    execute_workflow(NonDeterminismErrorGenericAsFailureWorkflow, max_cached_workflows: 0) do |handle|
      assert_eventually { assert handle.fetch_history_events.any?(&:workflow_task_completed_event_attributes) }
      handle.signal(NonDeterminismErrorGenericAsFailureWorkflow.finish)
      err = assert_raises(Temporalio::Error::WorkflowFailedError) { handle.result }
      assert_includes err.cause.message, 'Nondeterminism'
    end
  end

  class LoggerWorkflow < Temporalio::Workflow::Definition
    def initialize
      @bad_logger = Logger.new($stdout)
    end

    def execute
      Temporalio::Workflow.wait_condition { false }
    end

    workflow_update
    def update
      Temporalio::Workflow.logger.info('some-log-1')
      Temporalio::Workflow::Unsafe.illegal_call_tracing_disabled { @bad_logger.info('some-log-2') }
      sleep(0.01)
    end

    workflow_signal
    def cause_task_failure
      raise 'Some failure'
    end
  end

  def test_logger
    # Have to make a new logger so stdout after capturing here
    out, = capture_io do
      execute_workflow(LoggerWorkflow, max_cached_workflows: 0, logger: Logger.new($stdout)) do |handle|
        handle.execute_update(LoggerWorkflow.update)
        # Send signal which causes replay when cache disabled
        handle.signal(:some_signal)
      end
    end
    lines = out.split("\n")

    # Confirm there is only one good line and it has contextual info
    good_lines = lines.select { |l| l.include?('some-log-1') }
    assert_equal 1, good_lines.size
    assert_includes good_lines.first, ':workflow_type=>"LoggerWorkflow"'

    # Confirm there are two bad lines, and they don't have contextual info
    bad_lines = lines.select { |l| l.include?('some-log-2') }
    assert_equal 2, bad_lines.size
    refute_includes bad_lines.first, ':workflow_type=>"LoggerWorkflow"'

    # Confirm task failure logs
    out, = capture_io do
      execute_workflow(LoggerWorkflow, logger: Logger.new($stdout)) do |handle|
        handle.signal(LoggerWorkflow.cause_task_failure)
        assert_eventually_task_fail(handle:)
      end
    end
    lines = out.split("\n").select { |l| l.include?(':workflow_type=>"LoggerWorkflow"') }
    assert(lines.any? { |l| l.include?('Failed activation') && l.include?(':workflow_type=>"LoggerWorkflow"') })
    assert(lines.any? { |l| l.include?('Some failure') && l.include?(':workflow_type=>"LoggerWorkflow"') })
  end

  class CancelWorkflow < Temporalio::Workflow::Definition
    def execute(scenario)
      case scenario.to_sym
      when :swallow
        begin
          Temporalio::Workflow.wait_condition { false }
        rescue Temporalio::Error::CanceledError
          'done'
        end
      else
        raise NotImplementedError
      end
    end
  end

  def test_cancel
    execute_workflow(CancelWorkflow, :swallow) do |handle|
      assert_eventually { assert handle.fetch_history_events.any?(&:workflow_task_completed_event_attributes) }
      handle.cancel
      assert_equal 'done', handle.result
    end
  end

  class FutureWorkflowError < StandardError; end

  class FutureWorkflow < Temporalio::Workflow::Definition
    def execute(scenario)
      case scenario.to_sym
      when :any_of
        # Basic any of
        result = Temporalio::Workflow::Future.any_of(
          Temporalio::Workflow::Future.new { sleep(0.01) },
          Temporalio::Workflow::Future.new { 'done' }
        ).wait
        raise unless result == 'done'

        # Any of with exception
        begin
          Temporalio::Workflow::Future.any_of(
            Temporalio::Workflow::Future.new { sleep(0.01) },
            Temporalio::Workflow::Future.new { raise FutureWorkflowError }
          ).wait
          raise
        rescue FutureWorkflowError
          # Do nothing
        end

        # Try any of
        result = Temporalio::Workflow::Future.try_any_of(
          Temporalio::Workflow::Future.new { sleep(0.01) },
          Temporalio::Workflow::Future.new { 'done' }
        ).wait.wait
        raise unless result == 'done'

        # Try any of with exception
        try_any_of = Temporalio::Workflow::Future.try_any_of(
          Temporalio::Workflow::Future.new { sleep(0.01) },
          Temporalio::Workflow::Future.new { raise FutureWorkflowError }
        ).wait
        begin
          try_any_of.wait
          raise
        rescue FutureWorkflowError
          # Do nothing
        end
      when :all_of
        # Basic all of
        fut1 = Temporalio::Workflow::Future.new { 'done1' }
        fut2 = Temporalio::Workflow::Future.new { 'done2' }
        Temporalio::Workflow::Future.all_of(fut1, fut2).wait
        raise unless fut1.done? && fut2.done?

        # All of with exception
        fut1 = Temporalio::Workflow::Future.new { 'done1' }
        fut2 = Temporalio::Workflow::Future.new { raise FutureWorkflowError }
        begin
          Temporalio::Workflow::Future.all_of(fut1, fut2).wait
          raise
        rescue FutureWorkflowError
          # Do nothing
        end

        # Try all of
        fut1 = Temporalio::Workflow::Future.new { 'done1' }
        fut2 = Temporalio::Workflow::Future.new { 'done2' }
        Temporalio::Workflow::Future.try_all_of(fut1, fut2).wait
        raise unless fut1.done? && fut2.done?

        # Try all of with exception
        fut1 = Temporalio::Workflow::Future.new { 'done1' }
        fut2 = Temporalio::Workflow::Future.new { raise FutureWorkflowError }
        Temporalio::Workflow::Future.try_all_of(fut1, fut2).wait
        begin
          fut2.wait
          raise
        rescue FutureWorkflowError
          # Do nothing
        end
      when :set_result
        fut = Temporalio::Workflow::Future.new
        fut.result = 'some result'
        raise unless fut.wait == 'some result'
      when :set_failure
        fut = Temporalio::Workflow::Future.new
        fut.failure = FutureWorkflowError.new
        begin
          fut.wait
          raise
        rescue FutureWorkflowError
          # Do nothing
        end
        raise unless fut.wait_no_raise.nil?
        raise unless fut.failure.is_a?(FutureWorkflowError)
      when :cancel
        # Cancel does not affect future
        fut = Temporalio::Workflow::Future.new do
          Temporalio::Workflow.wait_condition { false }
        rescue Temporalio::Error::CanceledError
          'done'
        end
        fut.wait
      else
        raise NotImplementedError
      end
    end
  end

  def test_future
    execute_workflow(FutureWorkflow, :any_of)
    execute_workflow(FutureWorkflow, :all_of)
    execute_workflow(FutureWorkflow, :set_result)
    execute_workflow(FutureWorkflow, :set_failure)
    execute_workflow(FutureWorkflow, :cancel) do |handle|
      assert_eventually { assert handle.fetch_history_events.any?(&:workflow_task_completed_event_attributes) }
      handle.cancel
      assert_equal 'done', handle.result
    end
  end

  class FiberYieldWorkflow < Temporalio::Workflow::Definition
    def execute
      @fiber = Fiber.current
      Fiber.yield
    end

    workflow_signal
    def finish_workflow(value)
      Temporalio::Workflow.wait_condition { @fiber }.resume(value)
    end
  end

  def test_fiber_yield
    execute_workflow(FiberYieldWorkflow) do |handle|
      assert_eventually { assert handle.fetch_history_events.any?(&:workflow_task_completed_event_attributes) }
      handle.signal(FiberYieldWorkflow.finish_workflow, 'some-value')
      assert_equal 'some-value', handle.result
    end
  end

  # TODO(cretz): To test
  # * Common
  #   * Ractor with global state
  #   * Eager workflow start
  #   * Dynamic workflows
  #   * All async utilities (now, random/uuid, futures, mutexes, queues, etc)
  #   * Codec
  #   * Unawaited futures that have exceptions
  #   * Stack trace (including trimming our stuff)
  #     * Check timeout of a forever waiting future, this has a bad stack trace right now
  #     * Check error from signal handler or other handler, it may be too big of a stack trace right now
  #   * Enhanced stack trace
  #   * Separate abstract/interface
  #   * Patching
  #   * Failure in payload converter can fail workflow if proper error
  #   * Failure in failure converter (of activation error and workflow error)
  #   * Confirm GC post eviction
  #   * Custom metrics
  #   * Non-determinism
  #   * Replace worker client
  #   * Temporalio::Workflow mixed in instead of qualified
  #   * Reset update randomness seed
  # * Handler
  #   * Signals, queries, and updates (including dynamics and raw args and custom names and update validators)
  #   * Manually set signal, query, and update handlers (and signal buffering)
  #   * Signal, query, and update failures
  #   * Signal, query, and update bad argument
  #     * Note, for signals, it should just be logged and dropped, ref https://github.com/temporalio/sdk-dotnet/pull/114
  #   * Query does not trigger wait_condition
  #   * Query doing bad thing like adding command
  #   * Update validator doing bad thing like adding command
  #   * Handler unfinished policy
  #   * Update completion and workflow completion together (test both one waits on other and first wins)
  #   * Signal/update with start
  #   * Update current info
  #   * Update info in logs
  # * Activity
  #   * Simple activity, by name and reference
  #   * Simple local activity
  #   * Activity cancel (all cancellation types, and local)
  #   * Activity failures
  #   * Concurrent activities (any-of and all-of and raise/no-raise)
  #   * Local activity retry
  # * Child
  #   * Simple child workflow
  #   * Child workflow cancel
  #   * Signal child workflow
  #   * Child already started
  #   * Cancel (all cancellation types)
  #   * Parent close policies
  #   * Search attributes
  # * External
  #   * Signal external workflow
  #   * Cancel external workflow
end

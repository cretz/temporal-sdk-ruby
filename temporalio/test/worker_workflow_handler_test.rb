# frozen_string_literal: true

require 'temporalio/client'
require 'temporalio/testing'
require 'temporalio/worker'
require 'temporalio/workflow'
require 'test'
require 'workflow_utils'

class WorkerWorkflowHandlerTest < Test
  include WorkflowUtils

  class SimpleWorkflow < Temporalio::Workflow::Definition
    workflow_query_attr_reader :my_signal_result

    def execute
      Temporalio::Workflow.wait_condition { false }
    end

    workflow_signal
    def my_signal(arg)
      @my_signal_result = arg
    end

    workflow_query
    def my_query(arg)
      "Hello from query, #{arg}!"
    end

    workflow_update
    def my_update(arg)
      "Hello from update, #{arg}!"
    end
  end

  def test_simple
    execute_workflow(SimpleWorkflow) do |handle|
      handle.signal(SimpleWorkflow.my_signal, 'signal arg')
      assert_equal 'signal arg', handle.query(SimpleWorkflow.my_signal_result)
      assert_equal 'Hello from query, Temporal!', handle.query(SimpleWorkflow.my_query, 'Temporal')
      assert_equal 'Hello from update, Temporal!', handle.execute_update(SimpleWorkflow.my_update, 'Temporal')
    end
  end

  class ManualDefinitionWorkflow < Temporalio::Workflow::Definition
    workflow_query_attr_reader :signal_values

    def execute
      Temporalio::Workflow.query_handlers['my_query'] = Temporalio::Workflow::Definition::Query.new(
        name: 'my_query',
        to_invoke: proc { |arg1, arg2| [arg1, arg2] }
      )
      Temporalio::Workflow.update_handlers['my_update'] = Temporalio::Workflow::Definition::Update.new(
        name: 'my_update',
        to_invoke: proc { |arg1, arg2| [arg1, arg2] }
      )
      Temporalio::Workflow.wait_condition { false }
    end

    workflow_signal
    def define_signal_handler
      # Make a new signal definition and expect it to process buffer
      Temporalio::Workflow.signal_handlers['my_signal'] = Temporalio::Workflow::Definition::Signal.new(
        name: 'my_signal',
        to_invoke: proc { |arg1, arg2| (@signal_values ||= []) << [arg1, arg2] }
      )
    end
  end

  def test_manual_definition
    execute_workflow(ManualDefinitionWorkflow) do |handle|
      # Send 3 signals, then send a signal to define handler
      handle.signal(:my_signal, 'sig1-arg1', 'sig1-arg2')
      handle.signal(:my_signal, 'sig2-arg1', 'sig2-arg2')
      handle.signal(ManualDefinitionWorkflow.define_signal_handler)

      # Confirm buffer processed
      expected = [%w[sig1-arg1 sig1-arg2], %w[sig2-arg1 sig2-arg2]]
      assert_eventually { assert_equal expected, handle.query(ManualDefinitionWorkflow.signal_values) }

      # Send a another and confirm
      handle.signal(:my_signal, 'sig3-arg1', 'sig3-arg2')
      expected << %w[sig3-arg1 sig3-arg2]
      assert_eventually { assert_equal expected, handle.query(ManualDefinitionWorkflow.signal_values) }

      # Query and update
      assert_equal %w[q1 q2], handle.query('my_query', 'q1', 'q2')
      assert_equal %w[u1 u2], handle.execute_update('my_update', 'u1', 'u2')
    end
  end

  class CustomNameWorkflow < Temporalio::Workflow::Definition
    def execute
      Temporalio::Workflow.wait_condition { @finish_with }
    end

    workflow_signal name: :custom_name1
    def my_signal(finish_with)
      @finish_with = finish_with
    end

    workflow_query name: 'custom_name2'
    def my_query(arg)
      "query result for: #{arg}"
    end

    workflow_update name: '5'
    def my_update(arg)
      "update result for: #{arg}"
    end
  end

  def test_custom_name
    execute_workflow(CustomNameWorkflow) do |handle|
      assert_equal 'query result for: arg1', handle.query(CustomNameWorkflow.my_query, 'arg1')
      assert_equal 'query result for: arg2', handle.query('custom_name2', 'arg2')
      assert_equal 'query result for: arg3', handle.query(:custom_name2, 'arg3')
      assert_equal 'update result for: arg4', handle.execute_update('5', 'arg4')
      handle.signal(:custom_name1, 'done')
      assert_equal 'done', handle.result
    end
  end

  class ArgumentsWorkflow < Temporalio::Workflow::Definition
    workflow_query_attr_reader :signals

    def initialize
      @signals = []
    end

    def execute
      Temporalio::Workflow.wait_condition { false }
    end

    workflow_signal
    def some_signal(single_arg)
      @signals << single_arg
    end

    workflow_query
    def some_query(single_arg)
      "query done: #{single_arg}"
    end

    workflow_update
    def some_update(single_arg)
      "update done: #{single_arg}"
    end

    workflow_signal
    def some_signal_with_defaults(single_arg = 'default signal arg')
      @signals << single_arg
    end

    workflow_query
    def some_query_with_defaults(single_arg = 'default query arg')
      "query done: #{single_arg}"
    end

    workflow_update
    def some_update_with_defaults(single_arg = 'default update arg')
      "update done: #{single_arg}"
    end
  end

  def test_arguments
    # Too few/many args
    execute_workflow(ArgumentsWorkflow) do |handle|
      # For signals, too few are just dropped, too many are trimmed
      handle.signal(ArgumentsWorkflow.some_signal)
      handle.signal(ArgumentsWorkflow.some_signal, 'one')
      handle.signal(ArgumentsWorkflow.some_signal, 'one', 'two')
      assert_equal %w[one one], handle.query(ArgumentsWorkflow.signals)

      # For query, too few fail query, too many are trimmed
      err = assert_raises(Temporalio::Error::WorkflowQueryFailedError) { handle.query(ArgumentsWorkflow.some_query) }
      assert_includes err.message, 'wrong number of required arguments for some_query (given 0, expected 1)'
      assert_equal 'query done: one', handle.query(ArgumentsWorkflow.some_query, 'one')
      assert_equal 'query done: one', handle.query(ArgumentsWorkflow.some_query, 'one', 'two')

      # For update, too few fail update, too many are trimmed
      err = assert_raises(Temporalio::Error::WorkflowUpdateFailedError) do
        handle.execute_update(ArgumentsWorkflow.some_update)
      end
      assert_includes err.cause.message, 'wrong number of required arguments for some_update (given 0, expected 1)'
      assert_equal 'update done: one', handle.execute_update(ArgumentsWorkflow.some_update, 'one')
      assert_equal 'update done: one', handle.execute_update(ArgumentsWorkflow.some_update, 'one', 'two')
    end

    # Default parameters
    execute_workflow(ArgumentsWorkflow) do |handle|
      handle.signal(ArgumentsWorkflow.some_signal_with_defaults)
      handle.signal(ArgumentsWorkflow.some_signal_with_defaults, 'one')
      handle.signal(ArgumentsWorkflow.some_signal_with_defaults, 'one', 'two')
      assert_equal ['default signal arg', 'one', 'one'], handle.query(ArgumentsWorkflow.signals)

      assert_equal 'query done: default query arg', handle.query(ArgumentsWorkflow.some_query_with_defaults)
      assert_equal 'query done: one', handle.query(ArgumentsWorkflow.some_query_with_defaults, 'one')
      assert_equal 'query done: one', handle.query(ArgumentsWorkflow.some_query_with_defaults, 'one', 'two')

      assert_equal 'update done: default update arg', handle.execute_update(ArgumentsWorkflow.some_update_with_defaults)
      assert_equal 'update done: one', handle.execute_update(ArgumentsWorkflow.some_update_with_defaults, 'one')
      assert_equal 'update done: one', handle.execute_update(ArgumentsWorkflow.some_update_with_defaults, 'one', 'two')
    end
  end

  class DynamicWorkflow < Temporalio::Workflow::Definition
    def execute(manual_override)
      if manual_override
        Temporalio::Workflow.signal_handlers[nil] = Temporalio::Workflow::Definition::Signal.new(
          name: nil,
          raw_args: true,
          to_invoke: proc do |name, *args|
            arg_str = args.map do |v|
              Temporalio::Workflow.payload_converter.from_payload(v.payload)
            end.join(' -- ')
            @finish_with = "manual dyn signal: #{name} - #{arg_str}"
          end
        )
        Temporalio::Workflow.query_handlers[nil] = Temporalio::Workflow::Definition::Query.new(
          name: nil,
          raw_args: true,
          to_invoke: proc do |name, *args|
            arg_str = args.map { |v| Temporalio::Workflow.payload_converter.from_payload(v.payload) }.join(' -- ')
            "manual dyn query: #{name} - #{arg_str}"
          end
        )
        Temporalio::Workflow.update_handlers[nil] = Temporalio::Workflow::Definition::Update.new(
          name: nil,
          raw_args: true,
          to_invoke: proc do |name, *args|
            arg_str = args.map { |v| Temporalio::Workflow.payload_converter.from_payload(v.payload) }.join(' -- ')
            "manual dyn update: #{name} - #{arg_str}"
          end
        )
      end
      Temporalio::Workflow.wait_condition { @finish_with }
    end

    workflow_signal dynamic: true, raw_args: true
    def dynamic_signal(name, *args)
      arg_str = args.map { |v| Temporalio::Workflow.payload_converter.from_payload(v.payload) }.join(' -- ')
      @finish_with = "dyn signal: #{name} - #{arg_str}"
    end

    workflow_query dynamic: true, raw_args: true
    def dynamic_query(name, *args)
      arg_str = args.map { |v| Temporalio::Workflow.payload_converter.from_payload(v.payload) }.join(' -- ')
      "dyn query: #{name} - #{arg_str}"
    end

    workflow_update dynamic: true, raw_args: true
    def dynamic_update(name, *args)
      arg_str = args.map { |v| Temporalio::Workflow.payload_converter.from_payload(v.payload) }.join(' -- ')
      "dyn update: #{name} - #{arg_str}"
    end

    workflow_signal
    def non_dynamic_signal(*)
      # Do nothing
    end

    workflow_query
    def non_dynamic_query(*)
      'non-dynamic'
    end

    workflow_update
    def non_dynamic_update(*)
      'non-dynamic'
    end
  end

  def test_dynamic
    [true, false].each do |manual_override|
      prefix = manual_override ? 'manual ' : ''
      execute_workflow(DynamicWorkflow, manual_override) do |handle|
        # Non-dynamic
        handle.signal('non_dynamic_signal', 'signalarg1', 'signalarg2')
        assert_equal 'non-dynamic', handle.query('non_dynamic_query', 'queryarg1', 'queryarg2')
        assert_equal 'non-dynamic', handle.execute_update('non_dynamic_update', 'updatearg1', 'updatearg2')

        # Dynamic
        assert_equal "#{prefix}dyn query: non_dynamic_query_typo - queryarg1 -- queryarg2",
                     handle.query('non_dynamic_query_typo', 'queryarg1', 'queryarg2')
        assert_equal "#{prefix}dyn update: non_dynamic_update_typo - updatearg1 -- updatearg2",
                     handle.execute_update('non_dynamic_update_typo', 'updatearg1', 'updatearg2')
        handle.signal('non_dynamic_signal_typo', 'signalarg1', 'signalarg2')
        assert_equal "#{prefix}dyn signal: non_dynamic_signal_typo - signalarg1 -- signalarg2", handle.result
      end
    end
  end

  class UpdateValidatorWorkflow < Temporalio::Workflow::Definition
    def initialize
      Temporalio::Workflow.update_handlers['manual-update'] = Temporalio::Workflow::Definition::Update.new(
        name: 'manual-update',
        to_invoke: proc { |arg| "manual result for: #{arg}" },
        validator_to_invoke: proc { |arg| raise 'Bad manual arg' if arg == 'bad' }
      )
    end

    def execute
      Temporalio::Workflow.wait_condition { false }
    end

    workflow_update
    def some_update(arg)
      "result for: #{arg}"
    end

    workflow_update_validator :some_update
    def some_update_validator(arg)
      raise 'Bad arg' if arg == 'bad'
    end

    workflow_update dynamic: true
    def some_dynamic_update(_name, arg)
      "dyn result for: #{arg}"
    end

    workflow_update_validator :some_dynamic_update
    def some_dynamic_update_validator(_name, arg)
      raise 'Bad dyn arg' if arg == 'bad'
    end
  end

  def test_update_validator
    execute_workflow(UpdateValidatorWorkflow) do |handle|
      assert_equal 'manual result for: good', handle.execute_update('manual-update', 'good')
      assert_equal 'result for: good', handle.execute_update(UpdateValidatorWorkflow.some_update, 'good')
      assert_equal 'dyn result for: good', handle.execute_update('some_update_typo', 'good')

      err = assert_raises(Temporalio::Error::WorkflowUpdateFailedError) do
        handle.execute_update('manual-update', 'bad')
      end
      assert_equal 'Bad manual arg', err.cause.message
      err = assert_raises(Temporalio::Error::WorkflowUpdateFailedError) do
        handle.execute_update(UpdateValidatorWorkflow.some_update, 'bad')
      end
      assert_equal 'Bad arg', err.cause.message
      err = assert_raises(Temporalio::Error::WorkflowUpdateFailedError) do
        handle.execute_update('some_update_typo', 'bad')
      end
      assert_equal 'Bad dyn arg', err.cause.message
    end
  end
end

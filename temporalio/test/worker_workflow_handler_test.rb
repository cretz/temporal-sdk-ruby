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

      # TODO(cretz): Query and update
    end
  end
end

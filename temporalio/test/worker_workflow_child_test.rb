# frozen_string_literal: true

require 'securerandom'
require 'temporalio/client'
require 'temporalio/testing'
require 'temporalio/worker'
require 'temporalio/workflow'
require 'test'
require 'workflow_utils'

class WorkerWorkflowChildTest < Test
  include WorkflowUtils

  class SimpleChild < Temporalio::Workflow::Definition
    def execute(name)
      "Hello from child, #{name}!"
    end
  end

  class SimpleChildWorkflow < Temporalio::Workflow::Definition
    def execute(scenario)
      case scenario.to_sym
      when :simple
        Temporalio::Workflow.execute_child_workflow(SimpleChild, 'Temporal')
      when :symbol_name
        # TODO
      when :string_name
        # TODO
      else
        raise NotImplementedError
      end
    end
  end

  def test_simple_child
    result = execute_workflow(SimpleChildWorkflow, :simple, more_workflows: [SimpleChild])
    puts "!!! WUT: #{result}"
  end
end

# frozen_string_literal: true

require 'securerandom'
require 'temporalio/client'
require 'temporalio/testing'
require 'temporalio/worker'
require 'temporalio/workflow'
require 'test'
require 'workflow_utils'

class WorkerWorkflowActivityTest < Test
  include WorkflowUtils

  class SimpleActivity < Temporalio::Activity::Definition
    def execute(value)
      "from activity: #{value}"
    end
  end

  class SimpleActivityWorkflow < Temporalio::Workflow::Definition
    def execute(scenario)
      case scenario.to_sym
      when :remote
        Temporalio::Workflow.execute_activity(SimpleActivity, 'remote', start_to_close_timeout: 10)
      when :remote_symbol_name
        # TODO
      when :remote_string_name
        # TODO
      when :local
        Temporalio::Workflow.execute_local_activity(SimpleActivity, 'local', start_to_close_timeout: 10)
      when :local_symbol_name
        # TODO
      when :local_string_name
        # TODO
      else
        raise NotImplementedError
      end
    end
  end

  def test_simple_activity
    execute_workflow(SimpleActivityWorkflow, :remote, activities: [SimpleActivity]) do |handle|
      assert_equal 'from activity: remote', handle.result
      # Confirm remote activity completed
      assert handle.fetch_history_events.any?(&:activity_task_completed_event_attributes)
    end

    execute_workflow(SimpleActivityWorkflow, :local, activities: [SimpleActivity]) do |handle|
      assert_equal 'from activity: local', handle.result
      # Confirm local activity marker
      event = handle.fetch_history_events.find(&:marker_recorded_event_attributes)
      assert_equal 'core_local_activity', event.marker_recorded_event_attributes.marker_name
    end
  end
end

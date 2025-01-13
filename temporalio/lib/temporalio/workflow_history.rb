# frozen_string_literal: true

module Temporalio
  # Representation of a workflow's history.
  class WorkflowHistory
    def self.from_history_json(json)
      raise NotImplementedError, 'TODO'
    end

    # History events for the workflow.
    attr_reader :events

    # @!visibility private
    def initialize(events)
      @events = events
    end

    # @return [String] ID of the workflow, extracted from the first event.
    def workflow_id
      start = events.first&.workflow_execution_started_event_attributes
      raise 'First event not a start event' if start.nil?

      start.workflow_id
    end

    def self.to_history_json
      raise NotImplementedError, 'TODO'
    end
  end
end

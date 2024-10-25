# Code generated by protoc-gen-rbi. DO NOT EDIT.
# source: temporal/api/enums/v1/update.proto
# typed: strict

module Temporalio::Api::Enums::V1::UpdateWorkflowExecutionLifecycleStage
  self::UPDATE_WORKFLOW_EXECUTION_LIFECYCLE_STAGE_UNSPECIFIED = T.let(0, Integer)
  self::UPDATE_WORKFLOW_EXECUTION_LIFECYCLE_STAGE_ADMITTED = T.let(1, Integer)
  self::UPDATE_WORKFLOW_EXECUTION_LIFECYCLE_STAGE_ACCEPTED = T.let(2, Integer)
  self::UPDATE_WORKFLOW_EXECUTION_LIFECYCLE_STAGE_COMPLETED = T.let(3, Integer)

  sig { params(value: Integer).returns(T.nilable(Symbol)) }
  def self.lookup(value)
  end

  sig { params(value: Symbol).returns(T.nilable(Integer)) }
  def self.resolve(value)
  end

  sig { returns(::Google::Protobuf::EnumDescriptor) }
  def self.descriptor
  end
end

module Temporalio::Api::Enums::V1::UpdateAdmittedEventOrigin
  self::UPDATE_ADMITTED_EVENT_ORIGIN_UNSPECIFIED = T.let(0, Integer)
  self::UPDATE_ADMITTED_EVENT_ORIGIN_REAPPLY = T.let(1, Integer)

  sig { params(value: Integer).returns(T.nilable(Symbol)) }
  def self.lookup(value)
  end

  sig { params(value: Symbol).returns(T.nilable(Integer)) }
  def self.resolve(value)
  end

  sig { returns(::Google::Protobuf::EnumDescriptor) }
  def self.descriptor
  end
end

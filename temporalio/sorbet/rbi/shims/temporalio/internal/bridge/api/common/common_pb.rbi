# Code generated by protoc-gen-rbi. DO NOT EDIT.
# source: temporal/sdk/core/common/common.proto
# typed: strict

# Identifying information about a particular workflow execution, including namespace
class Temporalio::Internal::Bridge::Api::Common::NamespacedWorkflowExecution
  include ::Google::Protobuf::MessageExts
  extend ::Google::Protobuf::MessageExts::ClassMethods

  sig { params(str: String).returns(Temporalio::Internal::Bridge::Api::Common::NamespacedWorkflowExecution) }
  def self.decode(str)
  end

  sig { params(msg: Temporalio::Internal::Bridge::Api::Common::NamespacedWorkflowExecution).returns(String) }
  def self.encode(msg)
  end

  sig { params(str: String, kw: T.untyped).returns(Temporalio::Internal::Bridge::Api::Common::NamespacedWorkflowExecution) }
  def self.decode_json(str, **kw)
  end

  sig { params(msg: Temporalio::Internal::Bridge::Api::Common::NamespacedWorkflowExecution, kw: T.untyped).returns(String) }
  def self.encode_json(msg, **kw)
  end

  sig { returns(::Google::Protobuf::Descriptor) }
  def self.descriptor
  end

  sig do
    params(
      namespace: T.nilable(String),
      workflow_id: T.nilable(String),
      run_id: T.nilable(String)
    ).void
  end
  def initialize(
    namespace: "",
    workflow_id: "",
    run_id: ""
  )
  end

  # Namespace the workflow run is located in
  sig { returns(String) }
  def namespace
  end

  # Namespace the workflow run is located in
  sig { params(value: String).void }
  def namespace=(value)
  end

  # Namespace the workflow run is located in
  sig { void }
  def clear_namespace
  end

  # Can never be empty
  sig { returns(String) }
  def workflow_id
  end

  # Can never be empty
  sig { params(value: String).void }
  def workflow_id=(value)
  end

  # Can never be empty
  sig { void }
  def clear_workflow_id
  end

  # May be empty if the most recent run of the workflow with the given ID is being targeted
  sig { returns(String) }
  def run_id
  end

  # May be empty if the most recent run of the workflow with the given ID is being targeted
  sig { params(value: String).void }
  def run_id=(value)
  end

  # May be empty if the most recent run of the workflow with the given ID is being targeted
  sig { void }
  def clear_run_id
  end

  sig { params(field: String).returns(T.untyped) }
  def [](field)
  end

  sig { params(field: String, value: T.untyped).void }
  def []=(field, value)
  end

  sig { returns(T::Hash[Symbol, T.untyped]) }
  def to_h
  end
end

module Temporalio::Internal::Bridge::Api::Common::VersioningIntent
  self::UNSPECIFIED = T.let(0, Integer)
  self::COMPATIBLE = T.let(1, Integer)
  self::DEFAULT = T.let(2, Integer)

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

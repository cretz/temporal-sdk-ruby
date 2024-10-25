# Code generated by protoc-gen-rbi. DO NOT EDIT.
# source: temporal/api/enums/v1/batch_operation.proto
# typed: strict

module Temporalio::Api::Enums::V1::BatchOperationType
  self::BATCH_OPERATION_TYPE_UNSPECIFIED = T.let(0, Integer)
  self::BATCH_OPERATION_TYPE_TERMINATE = T.let(1, Integer)
  self::BATCH_OPERATION_TYPE_CANCEL = T.let(2, Integer)
  self::BATCH_OPERATION_TYPE_SIGNAL = T.let(3, Integer)
  self::BATCH_OPERATION_TYPE_DELETE = T.let(4, Integer)
  self::BATCH_OPERATION_TYPE_RESET = T.let(5, Integer)

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

module Temporalio::Api::Enums::V1::BatchOperationState
  self::BATCH_OPERATION_STATE_UNSPECIFIED = T.let(0, Integer)
  self::BATCH_OPERATION_STATE_RUNNING = T.let(1, Integer)
  self::BATCH_OPERATION_STATE_COMPLETED = T.let(2, Integer)
  self::BATCH_OPERATION_STATE_FAILED = T.let(3, Integer)

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

# Code generated by protoc-gen-rbi. DO NOT EDIT.
# source: temporal/api/common/v1/grpc_status.proto
# typed: strict

# From https://github.com/grpc/grpc/blob/master/src/proto/grpc/status/status.proto
# since we don't import grpc but still need the status info
class Temporalio::Api::Common::V1::GrpcStatus
  include ::Google::Protobuf::MessageExts
  extend ::Google::Protobuf::MessageExts::ClassMethods

  sig { params(str: String).returns(Temporalio::Api::Common::V1::GrpcStatus) }
  def self.decode(str)
  end

  sig { params(msg: Temporalio::Api::Common::V1::GrpcStatus).returns(String) }
  def self.encode(msg)
  end

  sig { params(str: String, kw: T.untyped).returns(Temporalio::Api::Common::V1::GrpcStatus) }
  def self.decode_json(str, **kw)
  end

  sig { params(msg: Temporalio::Api::Common::V1::GrpcStatus, kw: T.untyped).returns(String) }
  def self.encode_json(msg, **kw)
  end

  sig { returns(::Google::Protobuf::Descriptor) }
  def self.descriptor
  end

  sig do
    params(
      code: T.nilable(Integer),
      message: T.nilable(String),
      details: T.nilable(T::Array[T.nilable(Google::Protobuf::Any)])
    ).void
  end
  def initialize(
    code: 0,
    message: "",
    details: []
  )
  end

  sig { returns(Integer) }
  def code
  end

  sig { params(value: Integer).void }
  def code=(value)
  end

  sig { void }
  def clear_code
  end

  sig { returns(String) }
  def message
  end

  sig { params(value: String).void }
  def message=(value)
  end

  sig { void }
  def clear_message
  end

  sig { returns(T::Array[T.nilable(Google::Protobuf::Any)]) }
  def details
  end

  sig { params(value: ::Google::Protobuf::RepeatedField).void }
  def details=(value)
  end

  sig { void }
  def clear_details
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

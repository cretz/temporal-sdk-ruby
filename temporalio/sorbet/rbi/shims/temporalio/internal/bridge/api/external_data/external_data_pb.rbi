# Code generated by protoc-gen-rbi. DO NOT EDIT.
# source: temporal/sdk/core/external_data/external_data.proto
# typed: strict

class Temporalio::Internal::Bridge::Api::ExternalData::LocalActivityMarkerData
  include ::Google::Protobuf::MessageExts
  extend ::Google::Protobuf::MessageExts::ClassMethods

  sig { params(str: String).returns(Temporalio::Internal::Bridge::Api::ExternalData::LocalActivityMarkerData) }
  def self.decode(str)
  end

  sig { params(msg: Temporalio::Internal::Bridge::Api::ExternalData::LocalActivityMarkerData).returns(String) }
  def self.encode(msg)
  end

  sig { params(str: String, kw: T.untyped).returns(Temporalio::Internal::Bridge::Api::ExternalData::LocalActivityMarkerData) }
  def self.decode_json(str, **kw)
  end

  sig { params(msg: Temporalio::Internal::Bridge::Api::ExternalData::LocalActivityMarkerData, kw: T.untyped).returns(String) }
  def self.encode_json(msg, **kw)
  end

  sig { returns(::Google::Protobuf::Descriptor) }
  def self.descriptor
  end

  sig do
    params(
      seq: T.nilable(Integer),
      attempt: T.nilable(Integer),
      activity_id: T.nilable(String),
      activity_type: T.nilable(String),
      complete_time: T.nilable(Google::Protobuf::Timestamp),
      backoff: T.nilable(Google::Protobuf::Duration),
      original_schedule_time: T.nilable(Google::Protobuf::Timestamp)
    ).void
  end
  def initialize(
    seq: 0,
    attempt: 0,
    activity_id: "",
    activity_type: "",
    complete_time: nil,
    backoff: nil,
    original_schedule_time: nil
  )
  end

  sig { returns(Integer) }
  def seq
  end

  sig { params(value: Integer).void }
  def seq=(value)
  end

  sig { void }
  def clear_seq
  end

  # The number of attempts at execution before we recorded this result. Typically starts at 1,
# but it is possible to start at a higher number when backing off using a timer.
  sig { returns(Integer) }
  def attempt
  end

  # The number of attempts at execution before we recorded this result. Typically starts at 1,
# but it is possible to start at a higher number when backing off using a timer.
  sig { params(value: Integer).void }
  def attempt=(value)
  end

  # The number of attempts at execution before we recorded this result. Typically starts at 1,
# but it is possible to start at a higher number when backing off using a timer.
  sig { void }
  def clear_attempt
  end

  sig { returns(String) }
  def activity_id
  end

  sig { params(value: String).void }
  def activity_id=(value)
  end

  sig { void }
  def clear_activity_id
  end

  sig { returns(String) }
  def activity_type
  end

  sig { params(value: String).void }
  def activity_type=(value)
  end

  sig { void }
  def clear_activity_type
  end

  # You can think of this as "perceived completion time". It is the time the local activity thought
# it was when it completed. Which could be different from wall-clock time because of workflow
# replay. It's the WFT start time + the LA's runtime
  sig { returns(T.nilable(Google::Protobuf::Timestamp)) }
  def complete_time
  end

  # You can think of this as "perceived completion time". It is the time the local activity thought
# it was when it completed. Which could be different from wall-clock time because of workflow
# replay. It's the WFT start time + the LA's runtime
  sig { params(value: T.nilable(Google::Protobuf::Timestamp)).void }
  def complete_time=(value)
  end

  # You can think of this as "perceived completion time". It is the time the local activity thought
# it was when it completed. Which could be different from wall-clock time because of workflow
# replay. It's the WFT start time + the LA's runtime
  sig { void }
  def clear_complete_time
  end

  # If set, this local activity conceptually is retrying after the specified backoff.
# Implementation wise, they are really two different LA machines, but with the same type & input.
# The retry starts with an attempt number > 1.
  sig { returns(T.nilable(Google::Protobuf::Duration)) }
  def backoff
  end

  # If set, this local activity conceptually is retrying after the specified backoff.
# Implementation wise, they are really two different LA machines, but with the same type & input.
# The retry starts with an attempt number > 1.
  sig { params(value: T.nilable(Google::Protobuf::Duration)).void }
  def backoff=(value)
  end

  # If set, this local activity conceptually is retrying after the specified backoff.
# Implementation wise, they are really two different LA machines, but with the same type & input.
# The retry starts with an attempt number > 1.
  sig { void }
  def clear_backoff
  end

  # The time the LA was originally scheduled (wall clock time). This is used to track
# schedule-to-close timeouts when timer-based backoffs are used
  sig { returns(T.nilable(Google::Protobuf::Timestamp)) }
  def original_schedule_time
  end

  # The time the LA was originally scheduled (wall clock time). This is used to track
# schedule-to-close timeouts when timer-based backoffs are used
  sig { params(value: T.nilable(Google::Protobuf::Timestamp)).void }
  def original_schedule_time=(value)
  end

  # The time the LA was originally scheduled (wall clock time). This is used to track
# schedule-to-close timeouts when timer-based backoffs are used
  sig { void }
  def clear_original_schedule_time
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

class Temporalio::Internal::Bridge::Api::ExternalData::PatchedMarkerData
  include ::Google::Protobuf::MessageExts
  extend ::Google::Protobuf::MessageExts::ClassMethods

  sig { params(str: String).returns(Temporalio::Internal::Bridge::Api::ExternalData::PatchedMarkerData) }
  def self.decode(str)
  end

  sig { params(msg: Temporalio::Internal::Bridge::Api::ExternalData::PatchedMarkerData).returns(String) }
  def self.encode(msg)
  end

  sig { params(str: String, kw: T.untyped).returns(Temporalio::Internal::Bridge::Api::ExternalData::PatchedMarkerData) }
  def self.decode_json(str, **kw)
  end

  sig { params(msg: Temporalio::Internal::Bridge::Api::ExternalData::PatchedMarkerData, kw: T.untyped).returns(String) }
  def self.encode_json(msg, **kw)
  end

  sig { returns(::Google::Protobuf::Descriptor) }
  def self.descriptor
  end

  sig do
    params(
      id: T.nilable(String),
      deprecated: T.nilable(T::Boolean)
    ).void
  end
  def initialize(
    id: "",
    deprecated: false
  )
  end

  # The patch id
  sig { returns(String) }
  def id
  end

  # The patch id
  sig { params(value: String).void }
  def id=(value)
  end

  # The patch id
  sig { void }
  def clear_id
  end

  # Whether or not the patch is marked deprecated.
  sig { returns(T::Boolean) }
  def deprecated
  end

  # Whether or not the patch is marked deprecated.
  sig { params(value: T::Boolean).void }
  def deprecated=(value)
  end

  # Whether or not the patch is marked deprecated.
  sig { void }
  def clear_deprecated
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

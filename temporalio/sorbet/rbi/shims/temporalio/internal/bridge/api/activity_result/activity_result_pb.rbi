# Code generated by protoc-gen-rbi. DO NOT EDIT.
# source: temporal/sdk/core/activity_result/activity_result.proto
# typed: strict

# Used to report activity completions to core
class Temporalio::Internal::Bridge::Api::ActivityResult::ActivityExecutionResult
  include ::Google::Protobuf::MessageExts
  extend ::Google::Protobuf::MessageExts::ClassMethods

  sig { params(str: String).returns(Temporalio::Internal::Bridge::Api::ActivityResult::ActivityExecutionResult) }
  def self.decode(str)
  end

  sig { params(msg: Temporalio::Internal::Bridge::Api::ActivityResult::ActivityExecutionResult).returns(String) }
  def self.encode(msg)
  end

  sig { params(str: String, kw: T.untyped).returns(Temporalio::Internal::Bridge::Api::ActivityResult::ActivityExecutionResult) }
  def self.decode_json(str, **kw)
  end

  sig { params(msg: Temporalio::Internal::Bridge::Api::ActivityResult::ActivityExecutionResult, kw: T.untyped).returns(String) }
  def self.encode_json(msg, **kw)
  end

  sig { returns(::Google::Protobuf::Descriptor) }
  def self.descriptor
  end

  sig do
    params(
      completed: T.nilable(Temporalio::Internal::Bridge::Api::ActivityResult::Success),
      failed: T.nilable(Temporalio::Internal::Bridge::Api::ActivityResult::Failure),
      cancelled: T.nilable(Temporalio::Internal::Bridge::Api::ActivityResult::Cancellation),
      will_complete_async: T.nilable(Temporalio::Internal::Bridge::Api::ActivityResult::WillCompleteAsync)
    ).void
  end
  def initialize(
    completed: nil,
    failed: nil,
    cancelled: nil,
    will_complete_async: nil
  )
  end

  sig { returns(T.nilable(Temporalio::Internal::Bridge::Api::ActivityResult::Success)) }
  def completed
  end

  sig { params(value: T.nilable(Temporalio::Internal::Bridge::Api::ActivityResult::Success)).void }
  def completed=(value)
  end

  sig { void }
  def clear_completed
  end

  sig { returns(T.nilable(Temporalio::Internal::Bridge::Api::ActivityResult::Failure)) }
  def failed
  end

  sig { params(value: T.nilable(Temporalio::Internal::Bridge::Api::ActivityResult::Failure)).void }
  def failed=(value)
  end

  sig { void }
  def clear_failed
  end

  sig { returns(T.nilable(Temporalio::Internal::Bridge::Api::ActivityResult::Cancellation)) }
  def cancelled
  end

  sig { params(value: T.nilable(Temporalio::Internal::Bridge::Api::ActivityResult::Cancellation)).void }
  def cancelled=(value)
  end

  sig { void }
  def clear_cancelled
  end

  sig { returns(T.nilable(Temporalio::Internal::Bridge::Api::ActivityResult::WillCompleteAsync)) }
  def will_complete_async
  end

  sig { params(value: T.nilable(Temporalio::Internal::Bridge::Api::ActivityResult::WillCompleteAsync)).void }
  def will_complete_async=(value)
  end

  sig { void }
  def clear_will_complete_async
  end

  sig { returns(T.nilable(Symbol)) }
  def status
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

# Used to report activity resolutions to lang. IE: This is what the activities are resolved with
# in the workflow.
class Temporalio::Internal::Bridge::Api::ActivityResult::ActivityResolution
  include ::Google::Protobuf::MessageExts
  extend ::Google::Protobuf::MessageExts::ClassMethods

  sig { params(str: String).returns(Temporalio::Internal::Bridge::Api::ActivityResult::ActivityResolution) }
  def self.decode(str)
  end

  sig { params(msg: Temporalio::Internal::Bridge::Api::ActivityResult::ActivityResolution).returns(String) }
  def self.encode(msg)
  end

  sig { params(str: String, kw: T.untyped).returns(Temporalio::Internal::Bridge::Api::ActivityResult::ActivityResolution) }
  def self.decode_json(str, **kw)
  end

  sig { params(msg: Temporalio::Internal::Bridge::Api::ActivityResult::ActivityResolution, kw: T.untyped).returns(String) }
  def self.encode_json(msg, **kw)
  end

  sig { returns(::Google::Protobuf::Descriptor) }
  def self.descriptor
  end

  sig do
    params(
      completed: T.nilable(Temporalio::Internal::Bridge::Api::ActivityResult::Success),
      failed: T.nilable(Temporalio::Internal::Bridge::Api::ActivityResult::Failure),
      cancelled: T.nilable(Temporalio::Internal::Bridge::Api::ActivityResult::Cancellation),
      backoff: T.nilable(Temporalio::Internal::Bridge::Api::ActivityResult::DoBackoff)
    ).void
  end
  def initialize(
    completed: nil,
    failed: nil,
    cancelled: nil,
    backoff: nil
  )
  end

  sig { returns(T.nilable(Temporalio::Internal::Bridge::Api::ActivityResult::Success)) }
  def completed
  end

  sig { params(value: T.nilable(Temporalio::Internal::Bridge::Api::ActivityResult::Success)).void }
  def completed=(value)
  end

  sig { void }
  def clear_completed
  end

  sig { returns(T.nilable(Temporalio::Internal::Bridge::Api::ActivityResult::Failure)) }
  def failed
  end

  sig { params(value: T.nilable(Temporalio::Internal::Bridge::Api::ActivityResult::Failure)).void }
  def failed=(value)
  end

  sig { void }
  def clear_failed
  end

  sig { returns(T.nilable(Temporalio::Internal::Bridge::Api::ActivityResult::Cancellation)) }
  def cancelled
  end

  sig { params(value: T.nilable(Temporalio::Internal::Bridge::Api::ActivityResult::Cancellation)).void }
  def cancelled=(value)
  end

  sig { void }
  def clear_cancelled
  end

  sig { returns(T.nilable(Temporalio::Internal::Bridge::Api::ActivityResult::DoBackoff)) }
  def backoff
  end

  sig { params(value: T.nilable(Temporalio::Internal::Bridge::Api::ActivityResult::DoBackoff)).void }
  def backoff=(value)
  end

  sig { void }
  def clear_backoff
  end

  sig { returns(T.nilable(Symbol)) }
  def status
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

# Used to report successful completion either when executing or resolving
class Temporalio::Internal::Bridge::Api::ActivityResult::Success
  include ::Google::Protobuf::MessageExts
  extend ::Google::Protobuf::MessageExts::ClassMethods

  sig { params(str: String).returns(Temporalio::Internal::Bridge::Api::ActivityResult::Success) }
  def self.decode(str)
  end

  sig { params(msg: Temporalio::Internal::Bridge::Api::ActivityResult::Success).returns(String) }
  def self.encode(msg)
  end

  sig { params(str: String, kw: T.untyped).returns(Temporalio::Internal::Bridge::Api::ActivityResult::Success) }
  def self.decode_json(str, **kw)
  end

  sig { params(msg: Temporalio::Internal::Bridge::Api::ActivityResult::Success, kw: T.untyped).returns(String) }
  def self.encode_json(msg, **kw)
  end

  sig { returns(::Google::Protobuf::Descriptor) }
  def self.descriptor
  end

  sig do
    params(
      result: T.nilable(Temporalio::Api::Common::V1::Payload)
    ).void
  end
  def initialize(
    result: nil
  )
  end

  sig { returns(T.nilable(Temporalio::Api::Common::V1::Payload)) }
  def result
  end

  sig { params(value: T.nilable(Temporalio::Api::Common::V1::Payload)).void }
  def result=(value)
  end

  sig { void }
  def clear_result
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

# Used to report activity failure either when executing or resolving
class Temporalio::Internal::Bridge::Api::ActivityResult::Failure
  include ::Google::Protobuf::MessageExts
  extend ::Google::Protobuf::MessageExts::ClassMethods

  sig { params(str: String).returns(Temporalio::Internal::Bridge::Api::ActivityResult::Failure) }
  def self.decode(str)
  end

  sig { params(msg: Temporalio::Internal::Bridge::Api::ActivityResult::Failure).returns(String) }
  def self.encode(msg)
  end

  sig { params(str: String, kw: T.untyped).returns(Temporalio::Internal::Bridge::Api::ActivityResult::Failure) }
  def self.decode_json(str, **kw)
  end

  sig { params(msg: Temporalio::Internal::Bridge::Api::ActivityResult::Failure, kw: T.untyped).returns(String) }
  def self.encode_json(msg, **kw)
  end

  sig { returns(::Google::Protobuf::Descriptor) }
  def self.descriptor
  end

  sig do
    params(
      failure: T.nilable(Temporalio::Api::Failure::V1::Failure)
    ).void
  end
  def initialize(
    failure: nil
  )
  end

  sig { returns(T.nilable(Temporalio::Api::Failure::V1::Failure)) }
  def failure
  end

  sig { params(value: T.nilable(Temporalio::Api::Failure::V1::Failure)).void }
  def failure=(value)
  end

  sig { void }
  def clear_failure
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

# Used to report cancellation from both Core and Lang.
# When Lang reports a cancelled activity, it must put a CancelledFailure in the failure field.
# When Core reports a cancelled activity, it must put an ActivityFailure with CancelledFailure
# as the cause in the failure field.
class Temporalio::Internal::Bridge::Api::ActivityResult::Cancellation
  include ::Google::Protobuf::MessageExts
  extend ::Google::Protobuf::MessageExts::ClassMethods

  sig { params(str: String).returns(Temporalio::Internal::Bridge::Api::ActivityResult::Cancellation) }
  def self.decode(str)
  end

  sig { params(msg: Temporalio::Internal::Bridge::Api::ActivityResult::Cancellation).returns(String) }
  def self.encode(msg)
  end

  sig { params(str: String, kw: T.untyped).returns(Temporalio::Internal::Bridge::Api::ActivityResult::Cancellation) }
  def self.decode_json(str, **kw)
  end

  sig { params(msg: Temporalio::Internal::Bridge::Api::ActivityResult::Cancellation, kw: T.untyped).returns(String) }
  def self.encode_json(msg, **kw)
  end

  sig { returns(::Google::Protobuf::Descriptor) }
  def self.descriptor
  end

  sig do
    params(
      failure: T.nilable(Temporalio::Api::Failure::V1::Failure)
    ).void
  end
  def initialize(
    failure: nil
  )
  end

  sig { returns(T.nilable(Temporalio::Api::Failure::V1::Failure)) }
  def failure
  end

  sig { params(value: T.nilable(Temporalio::Api::Failure::V1::Failure)).void }
  def failure=(value)
  end

  sig { void }
  def clear_failure
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

# Used in ActivityExecutionResult to notify Core that this Activity will complete asynchronously.
# Core will forget about this Activity and free up resources used to track this Activity.
class Temporalio::Internal::Bridge::Api::ActivityResult::WillCompleteAsync
  include ::Google::Protobuf::MessageExts
  extend ::Google::Protobuf::MessageExts::ClassMethods

  sig { params(str: String).returns(Temporalio::Internal::Bridge::Api::ActivityResult::WillCompleteAsync) }
  def self.decode(str)
  end

  sig { params(msg: Temporalio::Internal::Bridge::Api::ActivityResult::WillCompleteAsync).returns(String) }
  def self.encode(msg)
  end

  sig { params(str: String, kw: T.untyped).returns(Temporalio::Internal::Bridge::Api::ActivityResult::WillCompleteAsync) }
  def self.decode_json(str, **kw)
  end

  sig { params(msg: Temporalio::Internal::Bridge::Api::ActivityResult::WillCompleteAsync, kw: T.untyped).returns(String) }
  def self.encode_json(msg, **kw)
  end

  sig { returns(::Google::Protobuf::Descriptor) }
  def self.descriptor
  end

  sig {void}
  def initialize; end

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

# Issued when a local activity needs to retry but also wants to back off more than would be
# reasonable to WFT heartbeat for. Lang is expected to schedule a timer for the duration
# and then start a local activity of the same type & same inputs with the provided attempt number
# after the timer has elapsed.
#
# This exists because Core does not have a concept of starting commands by itself, they originate
# from lang. So expecting lang to start the timer / next pass of the activity fits more smoothly.
class Temporalio::Internal::Bridge::Api::ActivityResult::DoBackoff
  include ::Google::Protobuf::MessageExts
  extend ::Google::Protobuf::MessageExts::ClassMethods

  sig { params(str: String).returns(Temporalio::Internal::Bridge::Api::ActivityResult::DoBackoff) }
  def self.decode(str)
  end

  sig { params(msg: Temporalio::Internal::Bridge::Api::ActivityResult::DoBackoff).returns(String) }
  def self.encode(msg)
  end

  sig { params(str: String, kw: T.untyped).returns(Temporalio::Internal::Bridge::Api::ActivityResult::DoBackoff) }
  def self.decode_json(str, **kw)
  end

  sig { params(msg: Temporalio::Internal::Bridge::Api::ActivityResult::DoBackoff, kw: T.untyped).returns(String) }
  def self.encode_json(msg, **kw)
  end

  sig { returns(::Google::Protobuf::Descriptor) }
  def self.descriptor
  end

  sig do
    params(
      attempt: T.nilable(Integer),
      backoff_duration: T.nilable(Google::Protobuf::Duration),
      original_schedule_time: T.nilable(Google::Protobuf::Timestamp)
    ).void
  end
  def initialize(
    attempt: 0,
    backoff_duration: nil,
    original_schedule_time: nil
  )
  end

  # The attempt number that lang should provide when scheduling the retry. If the LA failed
# on attempt 4 and we told lang to back off with a timer, this number will be 5.
  sig { returns(Integer) }
  def attempt
  end

  # The attempt number that lang should provide when scheduling the retry. If the LA failed
# on attempt 4 and we told lang to back off with a timer, this number will be 5.
  sig { params(value: Integer).void }
  def attempt=(value)
  end

  # The attempt number that lang should provide when scheduling the retry. If the LA failed
# on attempt 4 and we told lang to back off with a timer, this number will be 5.
  sig { void }
  def clear_attempt
  end

  sig { returns(T.nilable(Google::Protobuf::Duration)) }
  def backoff_duration
  end

  sig { params(value: T.nilable(Google::Protobuf::Duration)).void }
  def backoff_duration=(value)
  end

  sig { void }
  def clear_backoff_duration
  end

  # The time the first attempt of this local activity was scheduled. Must be passed with attempt
# to the retry LA.
  sig { returns(T.nilable(Google::Protobuf::Timestamp)) }
  def original_schedule_time
  end

  # The time the first attempt of this local activity was scheduled. Must be passed with attempt
# to the retry LA.
  sig { params(value: T.nilable(Google::Protobuf::Timestamp)).void }
  def original_schedule_time=(value)
  end

  # The time the first attempt of this local activity was scheduled. Must be passed with attempt
# to the retry LA.
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

# Code generated by protoc-gen-rbi. DO NOT EDIT.
# source: temporal/api/sdk/v1/task_complete_metadata.proto
# typed: strict

class Temporalio::Api::Sdk::V1::WorkflowTaskCompletedMetadata
  include ::Google::Protobuf::MessageExts
  extend ::Google::Protobuf::MessageExts::ClassMethods

  sig { params(str: String).returns(Temporalio::Api::Sdk::V1::WorkflowTaskCompletedMetadata) }
  def self.decode(str)
  end

  sig { params(msg: Temporalio::Api::Sdk::V1::WorkflowTaskCompletedMetadata).returns(String) }
  def self.encode(msg)
  end

  sig { params(str: String, kw: T.untyped).returns(Temporalio::Api::Sdk::V1::WorkflowTaskCompletedMetadata) }
  def self.decode_json(str, **kw)
  end

  sig { params(msg: Temporalio::Api::Sdk::V1::WorkflowTaskCompletedMetadata, kw: T.untyped).returns(String) }
  def self.encode_json(msg, **kw)
  end

  sig { returns(::Google::Protobuf::Descriptor) }
  def self.descriptor
  end

  sig do
    params(
      core_used_flags: T.nilable(T::Array[Integer]),
      lang_used_flags: T.nilable(T::Array[Integer]),
      sdk_name: T.nilable(String),
      sdk_version: T.nilable(String)
    ).void
  end
  def initialize(
    core_used_flags: [],
    lang_used_flags: [],
    sdk_name: "",
    sdk_version: ""
  )
  end

  # Internal flags used by the core SDK. SDKs using flags must comply with the following behavior:
#
# During replay:
# * If a flag is not recognized (value is too high or not defined), it must fail the workflow
#   task.
# * If a flag is recognized, it is stored in a set of used flags for the run. Code checks for
#   that flag during and after this WFT are allowed to assume that the flag is present.
# * If a code check for a flag does not find the flag in the set of used flags, it must take
#   the branch corresponding to the absence of that flag.
#
# During non-replay execution of new WFTs:
# * The SDK is free to use all flags it knows about. It must record any newly-used (IE: not
#   previously recorded) flags when completing the WFT.
#
# SDKs which are too old to even know about this field at all are considered to produce
# undefined behavior if they replay workflows which used this mechanism.
#
# (-- api-linter: core::0141::forbidden-types=disabled
#     aip.dev/not-precedent: These really shouldn't have negative values. --)
  sig { returns(T::Array[Integer]) }
  def core_used_flags
  end

  # Internal flags used by the core SDK. SDKs using flags must comply with the following behavior:
#
# During replay:
# * If a flag is not recognized (value is too high or not defined), it must fail the workflow
#   task.
# * If a flag is recognized, it is stored in a set of used flags for the run. Code checks for
#   that flag during and after this WFT are allowed to assume that the flag is present.
# * If a code check for a flag does not find the flag in the set of used flags, it must take
#   the branch corresponding to the absence of that flag.
#
# During non-replay execution of new WFTs:
# * The SDK is free to use all flags it knows about. It must record any newly-used (IE: not
#   previously recorded) flags when completing the WFT.
#
# SDKs which are too old to even know about this field at all are considered to produce
# undefined behavior if they replay workflows which used this mechanism.
#
# (-- api-linter: core::0141::forbidden-types=disabled
#     aip.dev/not-precedent: These really shouldn't have negative values. --)
  sig { params(value: ::Google::Protobuf::RepeatedField).void }
  def core_used_flags=(value)
  end

  # Internal flags used by the core SDK. SDKs using flags must comply with the following behavior:
#
# During replay:
# * If a flag is not recognized (value is too high or not defined), it must fail the workflow
#   task.
# * If a flag is recognized, it is stored in a set of used flags for the run. Code checks for
#   that flag during and after this WFT are allowed to assume that the flag is present.
# * If a code check for a flag does not find the flag in the set of used flags, it must take
#   the branch corresponding to the absence of that flag.
#
# During non-replay execution of new WFTs:
# * The SDK is free to use all flags it knows about. It must record any newly-used (IE: not
#   previously recorded) flags when completing the WFT.
#
# SDKs which are too old to even know about this field at all are considered to produce
# undefined behavior if they replay workflows which used this mechanism.
#
# (-- api-linter: core::0141::forbidden-types=disabled
#     aip.dev/not-precedent: These really shouldn't have negative values. --)
  sig { void }
  def clear_core_used_flags
  end

  # Flags used by the SDK lang. No attempt is made to distinguish between different SDK languages
# here as processing a workflow with a different language than the one which authored it is
# already undefined behavior. See `core_used_patches` for more.
#
# (-- api-linter: core::0141::forbidden-types=disabled
#     aip.dev/not-precedent: These really shouldn't have negative values. --)
  sig { returns(T::Array[Integer]) }
  def lang_used_flags
  end

  # Flags used by the SDK lang. No attempt is made to distinguish between different SDK languages
# here as processing a workflow with a different language than the one which authored it is
# already undefined behavior. See `core_used_patches` for more.
#
# (-- api-linter: core::0141::forbidden-types=disabled
#     aip.dev/not-precedent: These really shouldn't have negative values. --)
  sig { params(value: ::Google::Protobuf::RepeatedField).void }
  def lang_used_flags=(value)
  end

  # Flags used by the SDK lang. No attempt is made to distinguish between different SDK languages
# here as processing a workflow with a different language than the one which authored it is
# already undefined behavior. See `core_used_patches` for more.
#
# (-- api-linter: core::0141::forbidden-types=disabled
#     aip.dev/not-precedent: These really shouldn't have negative values. --)
  sig { void }
  def clear_lang_used_flags
  end

  # Name of the SDK that processed the task. This is usually something like "temporal-go" and is
# usually the same as client-name gRPC header. This should only be set if its value changed
# since the last time recorded on the workflow (or be set on the first task).
#
# (-- api-linter: core::0122::name-suffix=disabled
#     aip.dev/not-precedent: We're ok with a name suffix here. --)
  sig { returns(String) }
  def sdk_name
  end

  # Name of the SDK that processed the task. This is usually something like "temporal-go" and is
# usually the same as client-name gRPC header. This should only be set if its value changed
# since the last time recorded on the workflow (or be set on the first task).
#
# (-- api-linter: core::0122::name-suffix=disabled
#     aip.dev/not-precedent: We're ok with a name suffix here. --)
  sig { params(value: String).void }
  def sdk_name=(value)
  end

  # Name of the SDK that processed the task. This is usually something like "temporal-go" and is
# usually the same as client-name gRPC header. This should only be set if its value changed
# since the last time recorded on the workflow (or be set on the first task).
#
# (-- api-linter: core::0122::name-suffix=disabled
#     aip.dev/not-precedent: We're ok with a name suffix here. --)
  sig { void }
  def clear_sdk_name
  end

  # Version of the SDK that processed the task. This is usually something like "1.20.0" and is
# usually the same as client-version gRPC header. This should only be set if its value changed
# since the last time recorded on the workflow (or be set on the first task).
  sig { returns(String) }
  def sdk_version
  end

  # Version of the SDK that processed the task. This is usually something like "1.20.0" and is
# usually the same as client-version gRPC header. This should only be set if its value changed
# since the last time recorded on the workflow (or be set on the first task).
  sig { params(value: String).void }
  def sdk_version=(value)
  end

  # Version of the SDK that processed the task. This is usually something like "1.20.0" and is
# usually the same as client-version gRPC header. This should only be set if its value changed
# since the last time recorded on the workflow (or be set on the first task).
  sig { void }
  def clear_sdk_version
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

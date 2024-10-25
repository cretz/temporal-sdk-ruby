# Code generated by protoc-gen-rbi. DO NOT EDIT.
# source: temporal/api/errordetails/v1/message.proto
# typed: strict

class Temporalio::Api::ErrorDetails::V1::NotFoundFailure
  include ::Google::Protobuf::MessageExts
  extend ::Google::Protobuf::MessageExts::ClassMethods

  sig { params(str: String).returns(Temporalio::Api::ErrorDetails::V1::NotFoundFailure) }
  def self.decode(str)
  end

  sig { params(msg: Temporalio::Api::ErrorDetails::V1::NotFoundFailure).returns(String) }
  def self.encode(msg)
  end

  sig { params(str: String, kw: T.untyped).returns(Temporalio::Api::ErrorDetails::V1::NotFoundFailure) }
  def self.decode_json(str, **kw)
  end

  sig { params(msg: Temporalio::Api::ErrorDetails::V1::NotFoundFailure, kw: T.untyped).returns(String) }
  def self.encode_json(msg, **kw)
  end

  sig { returns(::Google::Protobuf::Descriptor) }
  def self.descriptor
  end

  sig do
    params(
      current_cluster: T.nilable(String),
      active_cluster: T.nilable(String)
    ).void
  end
  def initialize(
    current_cluster: "",
    active_cluster: ""
  )
  end

  sig { returns(String) }
  def current_cluster
  end

  sig { params(value: String).void }
  def current_cluster=(value)
  end

  sig { void }
  def clear_current_cluster
  end

  sig { returns(String) }
  def active_cluster
  end

  sig { params(value: String).void }
  def active_cluster=(value)
  end

  sig { void }
  def clear_active_cluster
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

class Temporalio::Api::ErrorDetails::V1::WorkflowExecutionAlreadyStartedFailure
  include ::Google::Protobuf::MessageExts
  extend ::Google::Protobuf::MessageExts::ClassMethods

  sig { params(str: String).returns(Temporalio::Api::ErrorDetails::V1::WorkflowExecutionAlreadyStartedFailure) }
  def self.decode(str)
  end

  sig { params(msg: Temporalio::Api::ErrorDetails::V1::WorkflowExecutionAlreadyStartedFailure).returns(String) }
  def self.encode(msg)
  end

  sig { params(str: String, kw: T.untyped).returns(Temporalio::Api::ErrorDetails::V1::WorkflowExecutionAlreadyStartedFailure) }
  def self.decode_json(str, **kw)
  end

  sig { params(msg: Temporalio::Api::ErrorDetails::V1::WorkflowExecutionAlreadyStartedFailure, kw: T.untyped).returns(String) }
  def self.encode_json(msg, **kw)
  end

  sig { returns(::Google::Protobuf::Descriptor) }
  def self.descriptor
  end

  sig do
    params(
      start_request_id: T.nilable(String),
      run_id: T.nilable(String)
    ).void
  end
  def initialize(
    start_request_id: "",
    run_id: ""
  )
  end

  sig { returns(String) }
  def start_request_id
  end

  sig { params(value: String).void }
  def start_request_id=(value)
  end

  sig { void }
  def clear_start_request_id
  end

  sig { returns(String) }
  def run_id
  end

  sig { params(value: String).void }
  def run_id=(value)
  end

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

class Temporalio::Api::ErrorDetails::V1::NamespaceNotActiveFailure
  include ::Google::Protobuf::MessageExts
  extend ::Google::Protobuf::MessageExts::ClassMethods

  sig { params(str: String).returns(Temporalio::Api::ErrorDetails::V1::NamespaceNotActiveFailure) }
  def self.decode(str)
  end

  sig { params(msg: Temporalio::Api::ErrorDetails::V1::NamespaceNotActiveFailure).returns(String) }
  def self.encode(msg)
  end

  sig { params(str: String, kw: T.untyped).returns(Temporalio::Api::ErrorDetails::V1::NamespaceNotActiveFailure) }
  def self.decode_json(str, **kw)
  end

  sig { params(msg: Temporalio::Api::ErrorDetails::V1::NamespaceNotActiveFailure, kw: T.untyped).returns(String) }
  def self.encode_json(msg, **kw)
  end

  sig { returns(::Google::Protobuf::Descriptor) }
  def self.descriptor
  end

  sig do
    params(
      namespace: T.nilable(String),
      current_cluster: T.nilable(String),
      active_cluster: T.nilable(String)
    ).void
  end
  def initialize(
    namespace: "",
    current_cluster: "",
    active_cluster: ""
  )
  end

  sig { returns(String) }
  def namespace
  end

  sig { params(value: String).void }
  def namespace=(value)
  end

  sig { void }
  def clear_namespace
  end

  sig { returns(String) }
  def current_cluster
  end

  sig { params(value: String).void }
  def current_cluster=(value)
  end

  sig { void }
  def clear_current_cluster
  end

  sig { returns(String) }
  def active_cluster
  end

  sig { params(value: String).void }
  def active_cluster=(value)
  end

  sig { void }
  def clear_active_cluster
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

class Temporalio::Api::ErrorDetails::V1::NamespaceInvalidStateFailure
  include ::Google::Protobuf::MessageExts
  extend ::Google::Protobuf::MessageExts::ClassMethods

  sig { params(str: String).returns(Temporalio::Api::ErrorDetails::V1::NamespaceInvalidStateFailure) }
  def self.decode(str)
  end

  sig { params(msg: Temporalio::Api::ErrorDetails::V1::NamespaceInvalidStateFailure).returns(String) }
  def self.encode(msg)
  end

  sig { params(str: String, kw: T.untyped).returns(Temporalio::Api::ErrorDetails::V1::NamespaceInvalidStateFailure) }
  def self.decode_json(str, **kw)
  end

  sig { params(msg: Temporalio::Api::ErrorDetails::V1::NamespaceInvalidStateFailure, kw: T.untyped).returns(String) }
  def self.encode_json(msg, **kw)
  end

  sig { returns(::Google::Protobuf::Descriptor) }
  def self.descriptor
  end

  sig do
    params(
      namespace: T.nilable(String),
      state: T.nilable(T.any(Symbol, String, Integer)),
      allowed_states: T.nilable(T::Array[T.any(Symbol, String, Integer)])
    ).void
  end
  def initialize(
    namespace: "",
    state: :NAMESPACE_STATE_UNSPECIFIED,
    allowed_states: []
  )
  end

  sig { returns(String) }
  def namespace
  end

  sig { params(value: String).void }
  def namespace=(value)
  end

  sig { void }
  def clear_namespace
  end

  # Current state of the requested namespace.
  sig { returns(T.any(Symbol, Integer)) }
  def state
  end

  # Current state of the requested namespace.
  sig { params(value: T.any(Symbol, String, Integer)).void }
  def state=(value)
  end

  # Current state of the requested namespace.
  sig { void }
  def clear_state
  end

  # Allowed namespace states for requested operation.
# For example NAMESPACE_STATE_DELETED is forbidden for most operations but allowed for DescribeNamespace.
  sig { returns(T::Array[T.any(Symbol, Integer)]) }
  def allowed_states
  end

  # Allowed namespace states for requested operation.
# For example NAMESPACE_STATE_DELETED is forbidden for most operations but allowed for DescribeNamespace.
  sig { params(value: ::Google::Protobuf::RepeatedField).void }
  def allowed_states=(value)
  end

  # Allowed namespace states for requested operation.
# For example NAMESPACE_STATE_DELETED is forbidden for most operations but allowed for DescribeNamespace.
  sig { void }
  def clear_allowed_states
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

class Temporalio::Api::ErrorDetails::V1::NamespaceNotFoundFailure
  include ::Google::Protobuf::MessageExts
  extend ::Google::Protobuf::MessageExts::ClassMethods

  sig { params(str: String).returns(Temporalio::Api::ErrorDetails::V1::NamespaceNotFoundFailure) }
  def self.decode(str)
  end

  sig { params(msg: Temporalio::Api::ErrorDetails::V1::NamespaceNotFoundFailure).returns(String) }
  def self.encode(msg)
  end

  sig { params(str: String, kw: T.untyped).returns(Temporalio::Api::ErrorDetails::V1::NamespaceNotFoundFailure) }
  def self.decode_json(str, **kw)
  end

  sig { params(msg: Temporalio::Api::ErrorDetails::V1::NamespaceNotFoundFailure, kw: T.untyped).returns(String) }
  def self.encode_json(msg, **kw)
  end

  sig { returns(::Google::Protobuf::Descriptor) }
  def self.descriptor
  end

  sig do
    params(
      namespace: T.nilable(String)
    ).void
  end
  def initialize(
    namespace: ""
  )
  end

  sig { returns(String) }
  def namespace
  end

  sig { params(value: String).void }
  def namespace=(value)
  end

  sig { void }
  def clear_namespace
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

class Temporalio::Api::ErrorDetails::V1::NamespaceAlreadyExistsFailure
  include ::Google::Protobuf::MessageExts
  extend ::Google::Protobuf::MessageExts::ClassMethods

  sig { params(str: String).returns(Temporalio::Api::ErrorDetails::V1::NamespaceAlreadyExistsFailure) }
  def self.decode(str)
  end

  sig { params(msg: Temporalio::Api::ErrorDetails::V1::NamespaceAlreadyExistsFailure).returns(String) }
  def self.encode(msg)
  end

  sig { params(str: String, kw: T.untyped).returns(Temporalio::Api::ErrorDetails::V1::NamespaceAlreadyExistsFailure) }
  def self.decode_json(str, **kw)
  end

  sig { params(msg: Temporalio::Api::ErrorDetails::V1::NamespaceAlreadyExistsFailure, kw: T.untyped).returns(String) }
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

class Temporalio::Api::ErrorDetails::V1::ClientVersionNotSupportedFailure
  include ::Google::Protobuf::MessageExts
  extend ::Google::Protobuf::MessageExts::ClassMethods

  sig { params(str: String).returns(Temporalio::Api::ErrorDetails::V1::ClientVersionNotSupportedFailure) }
  def self.decode(str)
  end

  sig { params(msg: Temporalio::Api::ErrorDetails::V1::ClientVersionNotSupportedFailure).returns(String) }
  def self.encode(msg)
  end

  sig { params(str: String, kw: T.untyped).returns(Temporalio::Api::ErrorDetails::V1::ClientVersionNotSupportedFailure) }
  def self.decode_json(str, **kw)
  end

  sig { params(msg: Temporalio::Api::ErrorDetails::V1::ClientVersionNotSupportedFailure, kw: T.untyped).returns(String) }
  def self.encode_json(msg, **kw)
  end

  sig { returns(::Google::Protobuf::Descriptor) }
  def self.descriptor
  end

  sig do
    params(
      client_version: T.nilable(String),
      client_name: T.nilable(String),
      supported_versions: T.nilable(String)
    ).void
  end
  def initialize(
    client_version: "",
    client_name: "",
    supported_versions: ""
  )
  end

  sig { returns(String) }
  def client_version
  end

  sig { params(value: String).void }
  def client_version=(value)
  end

  sig { void }
  def clear_client_version
  end

  sig { returns(String) }
  def client_name
  end

  sig { params(value: String).void }
  def client_name=(value)
  end

  sig { void }
  def clear_client_name
  end

  sig { returns(String) }
  def supported_versions
  end

  sig { params(value: String).void }
  def supported_versions=(value)
  end

  sig { void }
  def clear_supported_versions
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

class Temporalio::Api::ErrorDetails::V1::ServerVersionNotSupportedFailure
  include ::Google::Protobuf::MessageExts
  extend ::Google::Protobuf::MessageExts::ClassMethods

  sig { params(str: String).returns(Temporalio::Api::ErrorDetails::V1::ServerVersionNotSupportedFailure) }
  def self.decode(str)
  end

  sig { params(msg: Temporalio::Api::ErrorDetails::V1::ServerVersionNotSupportedFailure).returns(String) }
  def self.encode(msg)
  end

  sig { params(str: String, kw: T.untyped).returns(Temporalio::Api::ErrorDetails::V1::ServerVersionNotSupportedFailure) }
  def self.decode_json(str, **kw)
  end

  sig { params(msg: Temporalio::Api::ErrorDetails::V1::ServerVersionNotSupportedFailure, kw: T.untyped).returns(String) }
  def self.encode_json(msg, **kw)
  end

  sig { returns(::Google::Protobuf::Descriptor) }
  def self.descriptor
  end

  sig do
    params(
      server_version: T.nilable(String),
      client_supported_server_versions: T.nilable(String)
    ).void
  end
  def initialize(
    server_version: "",
    client_supported_server_versions: ""
  )
  end

  sig { returns(String) }
  def server_version
  end

  sig { params(value: String).void }
  def server_version=(value)
  end

  sig { void }
  def clear_server_version
  end

  sig { returns(String) }
  def client_supported_server_versions
  end

  sig { params(value: String).void }
  def client_supported_server_versions=(value)
  end

  sig { void }
  def clear_client_supported_server_versions
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

class Temporalio::Api::ErrorDetails::V1::CancellationAlreadyRequestedFailure
  include ::Google::Protobuf::MessageExts
  extend ::Google::Protobuf::MessageExts::ClassMethods

  sig { params(str: String).returns(Temporalio::Api::ErrorDetails::V1::CancellationAlreadyRequestedFailure) }
  def self.decode(str)
  end

  sig { params(msg: Temporalio::Api::ErrorDetails::V1::CancellationAlreadyRequestedFailure).returns(String) }
  def self.encode(msg)
  end

  sig { params(str: String, kw: T.untyped).returns(Temporalio::Api::ErrorDetails::V1::CancellationAlreadyRequestedFailure) }
  def self.decode_json(str, **kw)
  end

  sig { params(msg: Temporalio::Api::ErrorDetails::V1::CancellationAlreadyRequestedFailure, kw: T.untyped).returns(String) }
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

class Temporalio::Api::ErrorDetails::V1::QueryFailedFailure
  include ::Google::Protobuf::MessageExts
  extend ::Google::Protobuf::MessageExts::ClassMethods

  sig { params(str: String).returns(Temporalio::Api::ErrorDetails::V1::QueryFailedFailure) }
  def self.decode(str)
  end

  sig { params(msg: Temporalio::Api::ErrorDetails::V1::QueryFailedFailure).returns(String) }
  def self.encode(msg)
  end

  sig { params(str: String, kw: T.untyped).returns(Temporalio::Api::ErrorDetails::V1::QueryFailedFailure) }
  def self.decode_json(str, **kw)
  end

  sig { params(msg: Temporalio::Api::ErrorDetails::V1::QueryFailedFailure, kw: T.untyped).returns(String) }
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

class Temporalio::Api::ErrorDetails::V1::PermissionDeniedFailure
  include ::Google::Protobuf::MessageExts
  extend ::Google::Protobuf::MessageExts::ClassMethods

  sig { params(str: String).returns(Temporalio::Api::ErrorDetails::V1::PermissionDeniedFailure) }
  def self.decode(str)
  end

  sig { params(msg: Temporalio::Api::ErrorDetails::V1::PermissionDeniedFailure).returns(String) }
  def self.encode(msg)
  end

  sig { params(str: String, kw: T.untyped).returns(Temporalio::Api::ErrorDetails::V1::PermissionDeniedFailure) }
  def self.decode_json(str, **kw)
  end

  sig { params(msg: Temporalio::Api::ErrorDetails::V1::PermissionDeniedFailure, kw: T.untyped).returns(String) }
  def self.encode_json(msg, **kw)
  end

  sig { returns(::Google::Protobuf::Descriptor) }
  def self.descriptor
  end

  sig do
    params(
      reason: T.nilable(String)
    ).void
  end
  def initialize(
    reason: ""
  )
  end

  sig { returns(String) }
  def reason
  end

  sig { params(value: String).void }
  def reason=(value)
  end

  sig { void }
  def clear_reason
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

class Temporalio::Api::ErrorDetails::V1::ResourceExhaustedFailure
  include ::Google::Protobuf::MessageExts
  extend ::Google::Protobuf::MessageExts::ClassMethods

  sig { params(str: String).returns(Temporalio::Api::ErrorDetails::V1::ResourceExhaustedFailure) }
  def self.decode(str)
  end

  sig { params(msg: Temporalio::Api::ErrorDetails::V1::ResourceExhaustedFailure).returns(String) }
  def self.encode(msg)
  end

  sig { params(str: String, kw: T.untyped).returns(Temporalio::Api::ErrorDetails::V1::ResourceExhaustedFailure) }
  def self.decode_json(str, **kw)
  end

  sig { params(msg: Temporalio::Api::ErrorDetails::V1::ResourceExhaustedFailure, kw: T.untyped).returns(String) }
  def self.encode_json(msg, **kw)
  end

  sig { returns(::Google::Protobuf::Descriptor) }
  def self.descriptor
  end

  sig do
    params(
      cause: T.nilable(T.any(Symbol, String, Integer)),
      scope: T.nilable(T.any(Symbol, String, Integer))
    ).void
  end
  def initialize(
    cause: :RESOURCE_EXHAUSTED_CAUSE_UNSPECIFIED,
    scope: :RESOURCE_EXHAUSTED_SCOPE_UNSPECIFIED
  )
  end

  sig { returns(T.any(Symbol, Integer)) }
  def cause
  end

  sig { params(value: T.any(Symbol, String, Integer)).void }
  def cause=(value)
  end

  sig { void }
  def clear_cause
  end

  sig { returns(T.any(Symbol, Integer)) }
  def scope
  end

  sig { params(value: T.any(Symbol, String, Integer)).void }
  def scope=(value)
  end

  sig { void }
  def clear_scope
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

class Temporalio::Api::ErrorDetails::V1::SystemWorkflowFailure
  include ::Google::Protobuf::MessageExts
  extend ::Google::Protobuf::MessageExts::ClassMethods

  sig { params(str: String).returns(Temporalio::Api::ErrorDetails::V1::SystemWorkflowFailure) }
  def self.decode(str)
  end

  sig { params(msg: Temporalio::Api::ErrorDetails::V1::SystemWorkflowFailure).returns(String) }
  def self.encode(msg)
  end

  sig { params(str: String, kw: T.untyped).returns(Temporalio::Api::ErrorDetails::V1::SystemWorkflowFailure) }
  def self.decode_json(str, **kw)
  end

  sig { params(msg: Temporalio::Api::ErrorDetails::V1::SystemWorkflowFailure, kw: T.untyped).returns(String) }
  def self.encode_json(msg, **kw)
  end

  sig { returns(::Google::Protobuf::Descriptor) }
  def self.descriptor
  end

  sig do
    params(
      workflow_execution: T.nilable(Temporalio::Api::Common::V1::WorkflowExecution),
      workflow_error: T.nilable(String)
    ).void
  end
  def initialize(
    workflow_execution: nil,
    workflow_error: ""
  )
  end

  # WorkflowId and RunId of the Temporal system workflow performing the underlying operation.
# Looking up the info of the system workflow run may help identify the issue causing the failure.
  sig { returns(T.nilable(Temporalio::Api::Common::V1::WorkflowExecution)) }
  def workflow_execution
  end

  # WorkflowId and RunId of the Temporal system workflow performing the underlying operation.
# Looking up the info of the system workflow run may help identify the issue causing the failure.
  sig { params(value: T.nilable(Temporalio::Api::Common::V1::WorkflowExecution)).void }
  def workflow_execution=(value)
  end

  # WorkflowId and RunId of the Temporal system workflow performing the underlying operation.
# Looking up the info of the system workflow run may help identify the issue causing the failure.
  sig { void }
  def clear_workflow_execution
  end

  # Serialized error returned by the system workflow performing the underlying operation.
  sig { returns(String) }
  def workflow_error
  end

  # Serialized error returned by the system workflow performing the underlying operation.
  sig { params(value: String).void }
  def workflow_error=(value)
  end

  # Serialized error returned by the system workflow performing the underlying operation.
  sig { void }
  def clear_workflow_error
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

class Temporalio::Api::ErrorDetails::V1::WorkflowNotReadyFailure
  include ::Google::Protobuf::MessageExts
  extend ::Google::Protobuf::MessageExts::ClassMethods

  sig { params(str: String).returns(Temporalio::Api::ErrorDetails::V1::WorkflowNotReadyFailure) }
  def self.decode(str)
  end

  sig { params(msg: Temporalio::Api::ErrorDetails::V1::WorkflowNotReadyFailure).returns(String) }
  def self.encode(msg)
  end

  sig { params(str: String, kw: T.untyped).returns(Temporalio::Api::ErrorDetails::V1::WorkflowNotReadyFailure) }
  def self.decode_json(str, **kw)
  end

  sig { params(msg: Temporalio::Api::ErrorDetails::V1::WorkflowNotReadyFailure, kw: T.untyped).returns(String) }
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

class Temporalio::Api::ErrorDetails::V1::NewerBuildExistsFailure
  include ::Google::Protobuf::MessageExts
  extend ::Google::Protobuf::MessageExts::ClassMethods

  sig { params(str: String).returns(Temporalio::Api::ErrorDetails::V1::NewerBuildExistsFailure) }
  def self.decode(str)
  end

  sig { params(msg: Temporalio::Api::ErrorDetails::V1::NewerBuildExistsFailure).returns(String) }
  def self.encode(msg)
  end

  sig { params(str: String, kw: T.untyped).returns(Temporalio::Api::ErrorDetails::V1::NewerBuildExistsFailure) }
  def self.decode_json(str, **kw)
  end

  sig { params(msg: Temporalio::Api::ErrorDetails::V1::NewerBuildExistsFailure, kw: T.untyped).returns(String) }
  def self.encode_json(msg, **kw)
  end

  sig { returns(::Google::Protobuf::Descriptor) }
  def self.descriptor
  end

  sig do
    params(
      default_build_id: T.nilable(String)
    ).void
  end
  def initialize(
    default_build_id: ""
  )
  end

  # The current default compatible build ID which will receive tasks
  sig { returns(String) }
  def default_build_id
  end

  # The current default compatible build ID which will receive tasks
  sig { params(value: String).void }
  def default_build_id=(value)
  end

  # The current default compatible build ID which will receive tasks
  sig { void }
  def clear_default_build_id
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

class Temporalio::Api::ErrorDetails::V1::MultiOperationExecutionFailure
  include ::Google::Protobuf::MessageExts
  extend ::Google::Protobuf::MessageExts::ClassMethods

  sig { params(str: String).returns(Temporalio::Api::ErrorDetails::V1::MultiOperationExecutionFailure) }
  def self.decode(str)
  end

  sig { params(msg: Temporalio::Api::ErrorDetails::V1::MultiOperationExecutionFailure).returns(String) }
  def self.encode(msg)
  end

  sig { params(str: String, kw: T.untyped).returns(Temporalio::Api::ErrorDetails::V1::MultiOperationExecutionFailure) }
  def self.decode_json(str, **kw)
  end

  sig { params(msg: Temporalio::Api::ErrorDetails::V1::MultiOperationExecutionFailure, kw: T.untyped).returns(String) }
  def self.encode_json(msg, **kw)
  end

  sig { returns(::Google::Protobuf::Descriptor) }
  def self.descriptor
  end

  sig do
    params(
      statuses: T.nilable(T::Array[T.nilable(Temporalio::Api::ErrorDetails::V1::MultiOperationExecutionFailure::OperationStatus)])
    ).void
  end
  def initialize(
    statuses: []
  )
  end

  # One status for each requested operation from the failed MultiOperation. The failed
# operation(s) have the same error details as if it was executed separately. All other operations have the
# status code `Aborted` and `MultiOperationExecutionAborted` is added to the details field.
  sig { returns(T::Array[T.nilable(Temporalio::Api::ErrorDetails::V1::MultiOperationExecutionFailure::OperationStatus)]) }
  def statuses
  end

  # One status for each requested operation from the failed MultiOperation. The failed
# operation(s) have the same error details as if it was executed separately. All other operations have the
# status code `Aborted` and `MultiOperationExecutionAborted` is added to the details field.
  sig { params(value: ::Google::Protobuf::RepeatedField).void }
  def statuses=(value)
  end

  # One status for each requested operation from the failed MultiOperation. The failed
# operation(s) have the same error details as if it was executed separately. All other operations have the
# status code `Aborted` and `MultiOperationExecutionAborted` is added to the details field.
  sig { void }
  def clear_statuses
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

# NOTE: `OperationStatus` is modelled after
# [`google.rpc.Status`](https://github.com/googleapis/googleapis/blob/master/google/rpc/status.proto).
#
# (-- api-linter: core::0146::any=disabled
#     aip.dev/not-precedent: details are meant to hold arbitrary payloads. --)
class Temporalio::Api::ErrorDetails::V1::MultiOperationExecutionFailure::OperationStatus
  include ::Google::Protobuf::MessageExts
  extend ::Google::Protobuf::MessageExts::ClassMethods

  sig { params(str: String).returns(Temporalio::Api::ErrorDetails::V1::MultiOperationExecutionFailure::OperationStatus) }
  def self.decode(str)
  end

  sig { params(msg: Temporalio::Api::ErrorDetails::V1::MultiOperationExecutionFailure::OperationStatus).returns(String) }
  def self.encode(msg)
  end

  sig { params(str: String, kw: T.untyped).returns(Temporalio::Api::ErrorDetails::V1::MultiOperationExecutionFailure::OperationStatus) }
  def self.decode_json(str, **kw)
  end

  sig { params(msg: Temporalio::Api::ErrorDetails::V1::MultiOperationExecutionFailure::OperationStatus, kw: T.untyped).returns(String) }
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

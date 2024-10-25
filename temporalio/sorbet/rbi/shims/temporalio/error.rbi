module Temporalio
  class Error
    class RPCError
      module Code
        OK = T.let(T.unsafe(nil), Integer)
        CANCELLED = T.let(T.unsafe(nil), Integer)
        UNKNOWN = T.let(T.unsafe(nil), Integer)
        INVALID_ARGUMENT = T.let(T.unsafe(nil), Integer)
        DEADLINE_EXCEEDED = T.let(T.unsafe(nil), Integer)
        NOT_FOUND = T.let(T.unsafe(nil), Integer)
        ALREADY_EXISTS = T.let(T.unsafe(nil), Integer)
        PERMISSION_DENIED = T.let(T.unsafe(nil), Integer)
        RESOURCE_EXHAUSTED = T.let(T.unsafe(nil), Integer)
        FAILED_PRECONDITION = T.let(T.unsafe(nil), Integer)
        ABORTED = T.let(T.unsafe(nil), Integer)
        OUT_OF_RANGE = T.let(T.unsafe(nil), Integer)
        UNIMPLEMENTED = T.let(T.unsafe(nil), Integer)
        INTERNAL = T.let(T.unsafe(nil), Integer)
        UNAVAILABLE = T.let(T.unsafe(nil), Integer)
        DATA_LOSS = T.let(T.unsafe(nil), Integer)
        UNAUTHENTICATED = T.let(T.unsafe(nil), Integer)
      end
    end
  end
end

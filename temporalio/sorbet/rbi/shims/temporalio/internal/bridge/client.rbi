# typed: strict

module Temporalio
  module Internal
    module Bridge
      class Client
        SERVICE_WORKFLOW = T.let(T.unsafe(nil), Integer)
        SERVICE_OPERATOR = T.let(T.unsafe(nil), Integer)
        SERVICE_CLOUD = T.let(T.unsafe(nil), Integer)
        SERVICE_TEST = T.let(T.unsafe(nil), Integer)
        SERVICE_HEALTH = T.let(T.unsafe(nil), Integer)

        class RPCFailure < Error
          sig { returns(Integer) }
          def code; end

          sig { returns(String) }
          def message; end

          sig { returns(String) }
          def details; end
        end

        class CancellationToken
          sig { void }
          def details; end
        end
      end
    end
  end
end

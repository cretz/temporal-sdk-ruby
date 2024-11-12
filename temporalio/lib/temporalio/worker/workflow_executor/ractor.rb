# frozen_string_literal: true

require 'temporalio/internal/worker/workflow_instance'
require 'temporalio/worker/workflow_executor'

module Temporalio
  class Worker
    class WorkflowExecutor
      class Ractor < WorkflowExecutor
        include Singleton

        def initialize # rubocop:disable Lint/MissingSuper
          # Do nothing
        end

        def _validate_worker(worker, worker_options)
          raise 'Ractor support is not currently working, please set ' \
                'workflow_executor to Temporalio::Worker::WorkflowExecutor::ThreadPool'
        end

        def _activate(activation, worker_options, &)
          raise NotImplementedError
        end

        class Instance
          def initialize(initial_details)
            initial_details = ::Ractor.make_shareable(initial_details)

            @ractor = ::Ractor.new do
              # Receive initial details and create the instance
              details = ::Ractor.receive
              instance = Internal::Worker::WorkflowInstance.new(details)
              ::Ractor.yield

              # Now accept activations in a loop
              loop do
                activation = ::Ractor.receive
                completion = instance.activate(activation)
                ::Ractor.yield(completion)
              end
            end

            # Send initial details and wait until yielded
            @ractor.send(initial_details)
            @ractor.take
          end

          def activate(activation)
            @ractor.send(activation)
            @ractor.take
          end
        end

        private_constant :Instance
      end
    end
  end
end

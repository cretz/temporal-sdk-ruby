# frozen_string_literal: true

require 'temporalio/api/payload_visitor'
require 'temporalio/error'
require 'temporalio/internal/worker/workflow_instance'
require 'temporalio/scoped_logger'
require 'temporalio/workflow'
require 'temporalio/workflow/definition'
require 'timeout'

module Temporalio
  module Internal
    module Worker
      class WorkflowWorker
        def self.workflow_definitions(workflows)
          workflows.each_with_object({}) do |workflow, hash|
            # Load definition
            defn = begin
              if workflow.is_a?(Workflow::Definition::Info)
                workflow
              else
                Workflow::Definition::Info.from_class(workflow)
              end
            rescue StandardError
              raise ArgumentError, "Failed loading workflow #{workflow}"
            end

            # Confirm name not in use
            raise ArgumentError, "Multiple workflows named #{defn.name || '<dynamic>'}" if hash.key?(defn.name)

            hash[defn.name] = defn
          end
        end

        def initialize(worker:, bridge_worker:, workflow_definitions:)
          @executor = worker.options.workflow_executor

          payload_codec = worker.options.client.data_converter.payload_codec
          @workflow_payload_codec_thread_pool = worker.options.workflow_payload_codec_thread_pool
          if !Fiber.current_scheduler && payload_codec && !@workflow_payload_codec_thread_pool
            raise ArgumentError, 'Must have workflow payload codec thread pool if providing codec and not using fibers'
          end

          # If there is a payload codec, we need to build encoding and decoding visitors
          if payload_codec
            @payload_encoding_visitor = Api::PayloadVisitor.new(skip_search_attributes: true) do |payload|
              # TODO
            end
          end

          @options = Options.new(
            workflow_definitions:,
            bridge_worker:,
            logger: worker.options.logger,
            data_converter: worker.options.client.data_converter,
            deadlock_timeout: worker.options.debug_mode ? nil : 2,
            # TODO(cretz): Make this more performant for the default set?
            illegal_calls: WorkflowInstance::IllegalCallTracer.frozen_validated_illegal_calls(
              worker.options.illegal_workflow_calls || {}
            ),
            namespace: worker.options.client.namespace,
            task_queue: worker.options.task_queue,
            disable_eager_activity_execution: worker.options.disable_eager_activity_execution,
            workflow_interceptors: worker._workflow_interceptors,
            workflow_failure_exception_types: worker.options.workflow_failure_exception_types.map do |t|
              unless t.is_a?(Class) && t < Exception
                raise ArgumentError, 'All failure types must classes inheriting Exception'
              end

              t
            end.freeze
          )

          # Validate worker
          @executor._validate_worker(worker, @options)
        end

        def handle_activation(runner:, activation:, decoded:)
          # Encode in background if not encoded but it needs to be
          if @payload_codec && !decoded
            if Fiber.current_scheduler
              Fiber.schedule { decode_activation(runner, activation) }
            else
              @workflow_payload_codec_thread_pool.execute { decode_activation(runner, activation) }
            end
          else
            @executor._activate(activation, @options) do |activation_completion|
              runner.apply_workflow_activation_complete(workflow_worker: self, activation_completion:, encoded: false)
            end
          end
        rescue Exception => e # rubocop:disable Lint/RescueException
          # Should never happen, executors are expected to trap things
          @options.logger.error("Failed issuing activation on workflow run ID: #{activation.run_id}")
          @options.logger.error(e)
        end

        def handle_activation_complete(runner:, activation_completion:, encoded:, completion_complete_queue:)
          if @payload_codec && !encoded
            if Fiber.current_scheduler
              Fiber.schedule { encode_activation_completion(runner, activation_completion) }
            else
              @workflow_payload_codec_thread_pool.execute do
                encode_activation_completion(runner, activation_completion)
              end
            end
          else
            @options.bridge_worker.async_complete_workflow_activation(
              activation_completion.run_id, activation_completion.to_proto, completion_complete_queue
            )
          end
        end

        private

        def decode_activation(runner, activation)
          # TODO
          runner.apply_workflow_activation_decoded(workflow_worker: self, activation:)
        end

        def encode_activation_completion(runner, activation_completion)
          # TODO
          runner.apply_workflow_activation_complete(workflow_worker: self, activation_completion:, encoded: true)
        end

        class Options
          attr_reader :workflow_definitions, :bridge_worker, :logger, :data_converter, :deadlock_timeout,
                      :illegal_calls, :namespace, :task_queue, :disable_eager_activity_execution,
                      :workflow_interceptors, :workflow_failure_exception_types

          def initialize(
            workflow_definitions:, bridge_worker:, logger:, data_converter:, deadlock_timeout:,
            illegal_calls:, namespace:, task_queue:, disable_eager_activity_execution:,
            workflow_interceptors:, workflow_failure_exception_types:
          )
            @workflow_definitions = workflow_definitions
            @bridge_worker = bridge_worker
            @logger = logger
            @data_converter = data_converter
            @deadlock_timeout = deadlock_timeout
            @illegal_calls = illegal_calls
            @namespace = namespace
            @task_queue = task_queue
            @disable_eager_activity_execution = disable_eager_activity_execution
            @workflow_interceptors = workflow_interceptors
            @workflow_failure_exception_types = workflow_failure_exception_types
          end
        end
      end
    end
  end
end

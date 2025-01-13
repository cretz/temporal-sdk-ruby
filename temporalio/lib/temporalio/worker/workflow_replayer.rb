# frozen_string_literal: true

require 'temporalio/converters'
require 'temporalio/internal/bridge'
require 'temporalio/internal/bridge/worker'
require 'temporalio/internal/worker/workflow_worker'
require 'temporalio/worker/interceptor'
require 'temporalio/worker/thread_pool'
require 'temporalio/worker/tuner'
require 'temporalio/worker/workflow_executor'

module Temporalio
  class Worker
    class WorkflowReplayer
      Options = Struct.new(
        workflows:,
        namespace:,
        task_queue:,
        data_converter:,
        interceptors:,
        build_id:,
        identity:,
        logger:,
        illegal_workflow_calls:,
        workflow_failure_exception_types:,
        workflow_payload_codec_thread_pool:,
        debug_mode:,
        runtime:,
        keyword_init: true
      )

      attr_reader :options

      def initialize(
        workflows:,
        namespace: 'ReplayNamespace',
        task_queue: 'ReplayTaskQueue',
        data_converter: Converters::DataConverter.default,
        interceptors: [],
        build_id: Worker.default_build_id,
        identity: nil,
        logger: Logger.new($stdout, level: Logger::WARN),
        illegal_workflow_calls: Worker.default_illegal_workflow_calls,
        workflow_failure_exception_types: [],
        workflow_payload_codec_thread_pool: nil,
        debug_mode: %w[true 1].include?(ENV['TEMPORAL_DEBUG'].to_s.downcase),
        runtime: Runtime.default
      )
        @options = Options.new(
          workflows:,
          namespace:,
          task_queue:,
          data_converter:,
          interceptors:,
          build_id:,
          identity:,
          logger:,
          illegal_workflow_calls:,
          workflow_failure_exception_types:,
          workflow_payload_codec_thread_pool:,
          debug_mode:,
          runtime:,
          keyword_init: true
        ).freeze
        # Preload definitions and other settings
        @workflow_definitions = Internal::Worker::WorkflowWorker.workflow_definitions(workflows)
        @nondeterminism_as_workflow_fail, @nondeterminism_as_workflow_fail_for_types =
          Internal::Worker::WorkflowWorker.bridge_workflow_failure_exception_type_options(@workflow_definitions)
      end

      def replay_workflow(history, raise_on_replay_failure: true)
      end

      # TODO: No block means return collection of results
      def replay_workflows(histories, raise_on_replay_failure: false)
      end

      def with_runner(&)
        # Create the bridge worker and the replayer
        bridge_worker, replayer = Internal::Bridge::Worker::WorkerReplayer.new(
          runtime._core_runtime,
          Internal::Bridge::Worker::Options.new(
            activity: false,
            workflow: true,
            namespace:,
            task_queue:,
            tuner: Tuner.create_fixed(workflow_slots: 2, activity_slots: 1, local_activity_slots: 1)._to_bridge_options,
            build_id:,
            identity_override: identity,
            max_cached_workflows: 2,
            max_concurrent_workflow_task_polls: 1,
            nonsticky_to_sticky_poll_ratio: 1,
            max_concurrent_activity_task_polls: 1,
            no_remote_activities: true,
            sticky_queue_schedule_to_start_timeout: 1,
            max_heartbeat_throttle_interval: 1,
            default_heartbeat_throttle_interval: 1,
            max_worker_activities_per_second: 0,
            max_task_queue_activities_per_second: 0,
            graceful_shutdown_period: 0,
            use_worker_versioning: false,
            nondeterminism_as_workflow_fail: @nondeterminism_as_workflow_fail,
            nondeterminism_as_workflow_fail_for_types: @nondeterminism_as_workflow_fail_for_types
          )
        )

        # Create the workflow worker
        workflow_worker = Internal::Worker::WorkflowWorker.new(
          bridge_worker:,
          namespace: options.namespace,
          task_queue: options.task_queue,
          workflow_definitions: @workflow_definitions,
          workflow_executor: options.workflow_executor,
          logger: options.logger,
          data_converter: options.data_converter,
          metric_meter: options.runtime.metric_meter,
          workflow_interceptors: options.interceptors.select do |i|
            i.is_a?(Interceptor::Workflow)
          end,
          disable_eager_activity_execution: false,
          illegal_workflow_calls: options.illegal_workflow_calls,
          workflow_failure_exception_types: options.workflow_failure_exception_types,
          workflow_payload_codec_thread_pool: options.workflow_payload_codec_thread_pool,
          debug_mode: options.debug_mode
        )

        # TODO(cretz): Ug, just realized we're going to need to use the regular workflow stuff
        # for the multi-runner poll loop. We need to be able to provide the worker a built
        # bridge worker, so may have to abstract worker to "worker base" or something that
        # doesn't need a client 

        begin

        ensure
          workflow_worker.
        end
        # TODO
      end

      class ReplayResult
        attr_reader :history, :replay_failure

        def initialize(history:, replay_failure:)
          @history = history
          @replay_failure = replay_failure
        end
      end

      class ReplayRunner
        def initialize(bridge_replayer)
          @bridge_replayer = bridge_replayer
        end

        def replay_workflow(history, raise_on_replay_failure: true)
        end
      end
    end
  end
end

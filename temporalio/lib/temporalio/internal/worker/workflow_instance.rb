# frozen_string_literal: true

require 'temporalio'
require 'temporalio/activity/definition'
require 'temporalio/api'
require 'temporalio/converters/raw_value'
require 'temporalio/error'
require 'temporalio/internal/bridge/api'
require 'temporalio/internal/proto_utils'
require 'temporalio/retry_policy'
require 'temporalio/scoped_logger'
require 'temporalio/worker/interceptor'
require 'temporalio/workflow/info'
require 'temporalio/workflow/update_info'
require 'timeout'

module Temporalio
  module Internal
    module Worker
      class WorkflowInstance
        def self.new_completion_with_failure(run_id:, error:, failure_converter:, payload_converter:)
          Bridge::Api::WorkflowCompletion::WorkflowActivationCompletion.new(
            run_id: run_id,
            failed: Bridge::Api::WorkflowCompletion::Failure.new(
              failure: begin
                failure_converter.to_failure(error, payload_converter)
              rescue Exception => e # rubocop:disable Lint/RescueException
                Api::Failure::V1::Failure.new(
                  message: "Failed converting error to failure: #{e.message}, " \
                           "original error message: #{error.message}",
                  application_failure_info: Api::Failure::V1::ApplicationFailureInfo.new
                )
              end
            )
          )
        end

        attr_reader :context, :logger, :info, :scheduler, :disable_eager_activity_execution, :pending_activities,
                    :pending_timers, :pending_child_workflow_starts, :pending_child_workflows,
                    :payload_converter, :failure_converter, :cancellation,
                    :continue_as_new_suggested, :current_history_length, :current_history_size, :replaying, :random,
                    :signal_handlers, :query_handlers, :update_handlers,
                    :instance

        def initialize(details)
          # Create things needed before scheduling
          @context = Context.new(self)
          if details.illegal_calls && !details.illegal_calls.empty?
            @tracer = IllegalCallTracer.new(details.illegal_calls)
          end
          @logger = ReplaySafeLogger.new(logger: details.logger, instance: self)
          @logger.scoped_values_getter = proc { scoped_logger_info }
          @scheduler = Scheduler.new(self)

          # Run the rest in the scheduler
          run_in_scheduler { initialize_internal(details) }
        end

        def activate(activation)
          # Run inside of scheduler
          run_in_scheduler { activate_internal(activation) }
        end

        def add_command(command)
          @commands << command
        end

        def search_attributes
          # Lazy on first access
          @search_attributes ||= SearchAttributes._from_proto(@init_job.search_attributes, disable_mutations: true)
        end

        def memo
          # Lazy on first access
          @memo ||= ExternallyImmutableHash.new(ProtoUtils.memo_from_proto(@init_job.memo, payload_converter) || {})
        end

        def illegal_call_tracing_disabled(&)
          @tracer.disable(&)
        end

        private

        def run_in_scheduler(&)
          Fiber.set_scheduler(@scheduler)
          if @tracer
            @tracer.enable(&)
          else
            yield
          end
        ensure
          Fiber.set_scheduler(nil)
        end

        def initialize_internal(details)
          # Initialize general state
          @payload_converter = details.payload_converter
          @failure_converter = details.failure_converter
          @disable_eager_activity_execution = details.disable_eager_activity_execution
          @pending_activities = {} # Keyed by sequence, value is fiber to resume with proto result
          @pending_timers = {} # Keyed by sequence, value is fiber to resume with proto result
          @pending_child_workflow_starts = {} # Keyed by sequence, value is fiber to resume with proto result
          @pending_child_workflows = {} # Keyed by sequence, value is ChildWorkflowHandle to resolve with proto result
          @definition = details.definition
          @cancellation, @cancellation_proc = Cancellation.new
          @continue_as_new_suggested = false
          @current_history_length = 0
          @current_history_size = 0
          @replaying = false
          @failure_exception_types = details.workflow_failure_exception_types + @definition.failure_exception_types
          @signal_handlers = HandlerHash.new(details.definition.signals, Workflow::Definition::Signal) do |defn|
            # New definition, drain buffer
            # TODO(cretz): Dynamic
            @buffered_signals&.delete(defn.name)&.each { |job| apply_signal(job) }
          end
          @query_handlers = HandlerHash.new(details.definition.queries, Workflow::Definition::Query)
          @update_handlers = HandlerHash.new(details.definition.updates, Workflow::Definition::Update)

          # Create the info
          @init_job = details.initial_activation.jobs.find { |j| !j.initialize_workflow.nil? }&.initialize_workflow
          raise 'Missing init job from first activation' unless @init_job

          illegal_call_tracing_disabled do
            @info = Workflow::Info.new(
              attempt: @init_job.attempt,
              continued_run_id: ProtoUtils.string_or(@init_job.continued_from_execution_run_id),
              cron_schedule: ProtoUtils.string_or(@init_job.cron_schedule),
              execution_timeout: ProtoUtils.duration_to_seconds(@init_job.workflow_execution_timeout),
              last_failure: if @init_job.continued_failure
                              @failure_converter.from_failure(@init_job.continued_failure, @payload_converter)
                            end,
              last_result: if @init_job.last_completion_result
                             @payload_converter.from_payloads(@init_job.last_completion_result).first
                           end,
              namespace: details.namespace,
              parent: if @init_job.parent_workflow_info
                        Workflow::Info::ParentInfo.new(
                          namespace: @init_job.parent_workflow_info.namespace,
                          run_id: @init_job.parent_workflow_info.run_id,
                          workflow_id: @init_job.parent_workflow_info.workflow_id
                        )
                      end,
              retry_policy: (RetryPolicy._from_proto(@init_job.retry_policy) if @init_job.retry_policy),
              run_id: details.initial_activation.run_id,
              run_timeout: ProtoUtils.duration_to_seconds(@init_job.workflow_run_timeout),
              start_time: ProtoUtils.timestamp_to_time(details.initial_activation.timestamp) || raise,
              task_queue: details.task_queue,
              task_timeout: ProtoUtils.duration_to_seconds(@init_job.workflow_task_timeout),
              workflow_id: @init_job.workflow_id,
              workflow_type: @init_job.workflow_type
            ).freeze

            @random = Random.new(@init_job.randomness_seed)
          end

          # Convert workflow arguments
          @workflow_arguments = begin
            convert_args(payload_array: @init_job.arguments, method_name: :execute,
                         raw_args: details.definition.raw_args)
          rescue StandardError => e
            raise "Failed converting workflow input arguments: #{e}"
          end

          # Initialize interceptors
          @inbound = details.interceptors.reverse_each.reduce(InboundImplementation.new(self)) do |acc, int|
            int.intercept_workflow(acc)
          end
          @inbound.init(OutboundImplementation.new(self))

          # Create the user instance
          @instance = begin
            if details.definition.init
              details.definition.workflow_class.new(*@workflow_arguments)
            else
              details.definition.workflow_class.new
            end
          rescue StandardError => e
            raise "Failed creating workflow class: #{e}"
          end
        end

        def activate_internal(activation)
          # Reset some activation state
          @commands = []
          @current_activation_error = nil
          @continue_as_new_suggested = activation.continue_as_new_suggested
          @current_history_length = activation.history_length
          @current_history_size = activation.history_size_bytes
          @replaying = activation.is_replaying

          # Apply jobs and run event loop
          begin
            # Apply jobs
            activation.jobs.each { |job| apply(job) }

            # Schedule primary 'execute' if not already running (i.e. this is
            # the first activation)
            @primary_fiber ||= schedule(top_level: true) { run_workflow }

            # Run the event loop
            @scheduler.run_until_all_yielded
          rescue Exception => e # rubocop:disable Lint/RescueException
            @current_activation_error = e
          end

          # Return success or failure
          if @current_activation_error
            # TODO(cretz): Log activation failure
            @logger.replay_safety_disabled do
              @logger.warn('Failed activation')
              @logger.warn(@current_activation_error)
            end
            WorkflowInstance.new_completion_with_failure(
              run_id: activation.run_id,
              error: @current_activation_error,
              failure_converter: @failure_converter,
              payload_converter: @payload_converter
            )
          else
            Bridge::Api::WorkflowCompletion::WorkflowActivationCompletion.new(
              run_id: activation.run_id,
              successful: Bridge::Api::WorkflowCompletion::Success.new(commands: @commands)
            )
          end
        ensure
          @commands = nil
          @current_activation_error = nil
        end

        def apply(job)
          case job.variant
          when :initialize_workflow
            # Ignore
          when :fire_timer
            pending_timers.delete(job.fire_timer.seq)&.resume
          when :update_random_seed
            @random = illegal_call_tracing_disabled { Random.new(job.update_random_seed.randomness_seed) }
          when :query_workflow
            apply_query(job.query_workflow)
          when :cancel_workflow
            # TODO(cretz): Use the details somehow?
            @cancellation_proc.call(reason: 'Workflow canceled')
          when :signal_workflow
            apply_signal(job.signal_workflow)
          when :resolve_activity
            pending_activities.delete(job.resolve_activity.seq)&.resume(job.resolve_activity.result)
          when :resolve_child_workflow_execution_start
            pending_child_workflow_starts.delete(job.resolve_child_workflow_execution_start.seq)&.resume(
              job.resolve_child_workflow_execution_start
            )
          when :resolve_child_workflow_execution
            pending_child_workflows.delete(job.resolve_child_workflow_execution.seq)&._resolve(
              job.resolve_child_workflow_execution.result
            )
          when :do_update
            apply_update(job.do_update)
          else
            raise "Unrecognized activation job variant: #{job.variant}"
          end
        end

        def apply_signal(job)
          # Process as a top level handler so that errors are treated as if in primary workflow method
          # TODO(cretz): Dynamic
          defn = signal_handlers[job.signal_name]
          schedule(top_level: true, handler_defn: defn) do
            # Send to interceptor if there is a definition, buffer otherwise
            if defn
              @inbound.handle_signal(
                Temporalio::Worker::Interceptor::Workflow::HandleSignalInput.new(
                  signal: job.signal_name,
                  args: begin
                    convert_handler_args(payload_array: job.input, defn:)
                  rescue StandardError => e
                    # Signals argument conversion failure must not fail task
                    @logger.error("Failed converting signal input arguments for #{job.signal_name}")
                    @logger.error(e)
                    next
                  end,
                  definition: defn,
                  headers: ProtoUtils.headers_from_proto_map(job.headers, @payload_converter) || {}
                )
              )
            else
              buffered = (@buffered_signals ||= {})[job.signal_name]
              buffered = @buffered_signals[job.signal_name] = [] if buffered.nil?
              buffered << job
            end
          end
        end

        def apply_query(job)
          # TODO(cretz): Dynamic and __stack_trace and __temporal_workflow_metadata
          defn = case job.query_type
                 when '__stack_trace'
                   Workflow::Definition::Query.new(
                     name: '__stack_trace',
                     to_invoke: proc { scheduler.stack_trace }
                   )
                 else
                   query_handlers[job.query_type]
                 end
          schedule(handler_defn: defn) do
            unless defn
              raise "Query handler for #{job.query_type} expected but not found, " \
                    "known queries: [#{query_handlers.keys.compact.sort.join(', ')}]"
            end

            result = @inbound.handle_query(
              Temporalio::Worker::Interceptor::Workflow::HandleQueryInput.new(
                id: job.query_id,
                query: job.query_type,
                args: begin
                  convert_handler_args(payload_array: job.arguments, defn:)
                rescue StandardError => e
                  raise "Failed converting query input arguments: #{e}"
                end,
                definition: defn,
                headers: ProtoUtils.headers_from_proto_map(job.headers, @payload_converter) || {}
              )
            )
            add_command(
              Bridge::Api::WorkflowCommands::WorkflowCommand.new(
                respond_to_query: Bridge::Api::WorkflowCommands::QueryResult.new(
                  query_id: job.query_id,
                  succeeded: Bridge::Api::WorkflowCommands::QuerySuccess.new(
                    response: @payload_converter.to_payload(result)
                  )
                )
              )
            )
          rescue Exception => e # rubocop:disable Lint/RescueException
            add_command(
              Bridge::Api::WorkflowCommands::WorkflowCommand.new(
                respond_to_query: Bridge::Api::WorkflowCommands::QueryResult.new(
                  query_id: job.query_id,
                  failed: @failure_converter.to_failure(e, @payload_converter)
                )
              )
            )
          end
        end

        def apply_update(job)
          defn = update_handlers[job.name]
          schedule(handler_defn: defn) do
            # Until this is accepted, all errors are rejections
            accepted = false

            # Set update info
            Fiber[:__temporal_update_info] = Workflow::UpdateInfo.new(id: job.id, name: job.name).freeze

            # Reject if not present
            unless defn
              raise "Update handler for #{job.name} expected but not found, " \
                    "known updates: [#{update_handlers.keys.compact.sort.join(', ')}]"
            end

            # To match other SDKs, we are only calling the validation interceptor if there is a validator. Also to match
            # other SDKs, we are re-converting the args between validate and update to disallow user mutation in
            # validator/interceptor.
            if job.run_validator && defn.validator_to_invoke
              @inbound.validate_update(
                Temporalio::Worker::Interceptor::Workflow::HandleUpdateInput.new(
                  id: job.id,
                  update: job.name,
                  args: begin
                    convert_handler_args(payload_array: job.input, defn:)
                  rescue StandardError => e
                    raise "Failed converting update input arguments: #{e}"
                  end,
                  definition: defn,
                  headers: ProtoUtils.headers_from_proto_map(job.headers, @payload_converter) || {}
                )
              )
            end

            # We build the input before marking accepted so the exception can reject instead of fail task
            input = Temporalio::Worker::Interceptor::Workflow::HandleUpdateInput.new(
              id: job.id,
              update: job.name,
              args: begin
                convert_handler_args(payload_array: job.input, defn:)
              rescue StandardError => e
                raise "Failed converting update input arguments: #{e}"
              end,
              definition: defn,
              headers: ProtoUtils.headers_from_proto_map(job.headers, @payload_converter) || {}
            )

            # Accept
            add_command(
              Bridge::Api::WorkflowCommands::WorkflowCommand.new(
                update_response: Bridge::Api::WorkflowCommands::UpdateResponse.new(
                  protocol_instance_id: job.protocol_instance_id,
                  accepted: Google::Protobuf::Empty.new
                )
              )
            )
            accepted = true

            # Issue update
            result = @inbound.handle_update(input)
            add_command(
              Bridge::Api::WorkflowCommands::WorkflowCommand.new(
                update_response: Bridge::Api::WorkflowCommands::UpdateResponse.new(
                  protocol_instance_id: job.protocol_instance_id,
                  completed: @payload_converter.to_payload(result)
                )
              )
            )
          rescue Exception => e # rubocop:disable Lint/RescueException
            # Re-raise to cause task failure if this is accepted but this is not a failure exception
            raise if accepted && !failure_exception?(e)

            # Reject
            add_command(
              Bridge::Api::WorkflowCommands::WorkflowCommand.new(
                update_response: Bridge::Api::WorkflowCommands::UpdateResponse.new(
                  protocol_instance_id: job.protocol_instance_id,
                  rejected: @failure_converter.to_failure(e, @payload_converter)
                )
              )
            )
          end
        end

        def run_workflow
          result = @inbound.execute(
            Temporalio::Worker::Interceptor::Workflow::ExecuteInput.new(
              args: @workflow_arguments,
              headers: ProtoUtils.headers_from_proto_map(@init_job.headers, @payload_converter) || {}
            )
          )
          add_command(
            Bridge::Api::WorkflowCommands::WorkflowCommand.new(
              complete_workflow_execution: Bridge::Api::WorkflowCommands::CompleteWorkflowExecution.new(
                result: @payload_converter.to_payload(result)
              )
            )
          )
        end

        def schedule(
          top_level: false,
          handler_defn: nil,
          &
        )
          # TODO(cretz): Handler definition finish policy
          Fiber.schedule do
            yield
          rescue Exception => e # rubocop:disable Lint/RescueException
            if top_level && e.is_a?(Workflow::ContinueAsNewError)
              @logger.debug('Workflow requested continue as new')
              add_command(
                Bridge::Api::WorkflowCommands::WorkflowCommand.new(
                  continue_as_new_workflow_execution: Bridge::Api::WorkflowCommands::ContinueAsNewWorkflowExecution.new(
                    workflow_type: e.workflow,
                    task_queue: e.task_queue,
                    arguments: ProtoUtils.convert_to_payload_array(payload_converter, e.args),
                    workflow_run_timeout: ProtoUtils.seconds_to_duration(e.run_timeout),
                    workflow_task_timeout: ProtoUtils.seconds_to_duration(e.task_timeout),
                    memo: ProtoUtils.memo_to_proto_hash(e.memo, payload_converter),
                    headers: ProtoUtils.headers_to_proto(e.headers, payload_converter),
                    search_attributes: e.search_attributes&._to_proto,
                    retry_policy: e.retry_policy&._to_proto
                  )
                )
              )
            elsif top_level && @cancellation.canceled? && Error.canceled?(e)
              # If cancel was ever requested and this is a cancellation or an activity/child cancellation, we add a
              # cancel command. Technically this means that a swallowed cancel followed by, say, an activity cancel
              # later on will show the workflow as cancelled. But this is a Temporal limitation in that cancellation is
              # a state not an event.
              @logger.debug('Workflow requested to cancel and properly raised cancel')
              @logger.debug(e)
              add_command(
                Bridge::Api::WorkflowCommands::WorkflowCommand.new(
                  cancel_workflow_execution: Bridge::Api::WorkflowCommands::CancelWorkflowExecution.new
                )
              )
            elsif top_level && failure_exception?(e)
              @logger.debug('Workflow raised failure')
              @logger.debug(e)
              add_command(
                Bridge::Api::WorkflowCommands::WorkflowCommand.new(
                  fail_workflow_execution: Bridge::Api::WorkflowCommands::FailWorkflowExecution.new(
                    failure: @failure_converter.to_failure(e, @payload_converter)
                  )
                )
              )
            else
              @current_activation_error ||= e
            end
          end
        end

        def failure_exception?(err)
          err.is_a?(Error::Failure) || err.is_a?(Timeout::Error) || @failure_exception_types.any? do |cls|
            err.is_a?(cls)
          end
        end

        def convert_handler_args(payload_array:, defn:)
          convert_args(
            payload_array:,
            method_name: defn.to_invoke.is_a?(Symbol) ? defn.to_invoke : nil,
            raw_args: defn.raw_args,
            ignore_first_param: defn.name.nil? # Dynamic
          )
        end

        def convert_args(payload_array:, method_name:, raw_args:, ignore_first_param: false)
          # Just in case it is not an array
          payload_array = payload_array.to_ary

          # We want to discard extra arguments if we can. If there is a method
          # name, try to look it up. Then, assuming there's no :rest, trim args
          # to the amount of :req or :opt there are.
          if method_name && @definition.workflow_class.method_defined?(method_name)
            count = 0
            @definition.workflow_class.instance_method(method_name).parameters.each do |(type, _)|
              if type == :rest
                count = nil
                break
              elsif %i[req opt].include?(type)
                count += 1
              end
            end
            count -= 1 if ignore_first_param
            payload_array = payload_array.take(count) if count
          end

          # Convert
          if raw_args
            payload_array.map { |p| Converters::RawValue.new(p) }
          else
            ProtoUtils.convert_from_payload_array(@payload_converter, payload_array)
          end
        end

        def scoped_logger_info
          @scoped_logger_info ||= {
            attempt: info.attempt,
            namespace: info.namespace,
            run_id: info.run_id,
            task_queue: info.task_queue,
            workflow_id: info.workflow_id,
            workflow_type: info.workflow_type
          }
        end

        # TODO(cretz): Pull this out of this file
        class Context
          def initialize(instance)
            @instance = instance
          end

          def cancellation
            @instance.cancellation
          end

          def continue_as_new_suggested
            @instance.continue_as_new_suggested
          end

          def current_history_length
            @instance.current_history_length
          end

          def current_history_size
            @instance.current_history_size
          end

          def current_update_info
            Fiber[:__temporal_update_info]
          end

          def execute_activity(
            activity,
            *args,
            task_queue:,
            schedule_to_close_timeout:,
            schedule_to_start_timeout:,
            start_to_close_timeout:,
            heartbeat_timeout:,
            retry_policy:,
            cancellation:,
            cancellation_type:,
            activity_id:,
            disable_eager_execution:
          )
            @outbound.execute_activity(
              Temporalio::Worker::Interceptor::Workflow::ExecuteActivityInput.new(
                activity:,
                args:,
                task_queue: task_queue || info.task_queue,
                schedule_to_close_timeout:,
                schedule_to_start_timeout:,
                start_to_close_timeout:,
                heartbeat_timeout:,
                retry_policy:,
                cancellation:,
                cancellation_type:,
                activity_id:,
                disable_eager_execution: disable_eager_execution || @instance.disable_eager_activity_execution,
                headers: {}
              )
            )
          end

          def execute_local_activity(
            activity,
            *args,
            schedule_to_close_timeout:,
            schedule_to_start_timeout:,
            start_to_close_timeout:,
            retry_policy:,
            local_retry_threshold:,
            cancellation:,
            cancellation_type:,
            activity_id:
          )
            @outbound.execute_local_activity(
              Temporalio::Worker::Interceptor::Workflow::ExecuteLocalActivityInput.new(
                activity:,
                args:,
                schedule_to_close_timeout:,
                schedule_to_start_timeout:,
                start_to_close_timeout:,
                retry_policy:,
                local_retry_threshold:,
                cancellation:,
                cancellation_type:,
                activity_id:,
                headers: {}
              )
            )
          end

          def illegal_call_tracing_disabled(&)
            @instance.illegal_call_tracing_disabled(&)
          end

          def info
            @instance.info
          end

          def initialize_continue_as_new_error(error)
            @outbound.initialize_continue_as_new_error(
              Temporalio::Worker::Interceptor::Workflow::InitializeContinueAsNewErrorInput.new(error:)
            )
          end

          def logger
            @instance.logger
          end

          def memo
            @instance.memo
          end

          def payload_converter
            @instance.payload_converter
          end

          def query_handlers
            @instance.query_handlers
          end

          def random
            @instance.random
          end

          def replaying?
            @instance.replaying
          end

          def search_attributes
            @instance.search_attributes
          end

          def signal_handlers
            @instance.signal_handlers
          end

          def sleep(duration, summary:, cancellation:)
            @outbound.sleep(
              Temporalio::Worker::Interceptor::Workflow::SleepInput.new(
                duration:,
                summary:,
                cancellation:
              )
            )
          end

          def start_child_workflow(
            workflow,
            *args,
            id:,
            task_queue:,
            cancellation:,
            cancellation_type:,
            parent_close_policy:,
            execution_timeout:,
            run_timeout:,
            task_timeout:,
            id_reuse_policy:,
            retry_policy:,
            cron_schedule:,
            memo:,
            search_attributes:
          )
            @outbound.start_child_workflow(
              Temporalio::Worker::Interceptor::Workflow::StartChildWorkflowInput.new(
                workflow:,
                args:,
                id:,
                task_queue:,
                cancellation:,
                cancellation_type:,
                parent_close_policy:,
                execution_timeout:,
                run_timeout:,
                task_timeout:,
                id_reuse_policy:,
                retry_policy:,
                cron_schedule:,
                memo:,
                search_attributes:,
                headers: {}
              )
            )
          end

          def timeout(duration, exception_class, *exception_args, summary:, &)
            # Run timer in background and block in foreground. This gives better stack traces than a future any-of race.
            # We make a detached cancellation because we don't want to link to workflow cancellation.
            sleep_cancel, sleep_cancel_proc = Cancellation.new
            fiber = Fiber.current
            Workflow::Future.new do
              Workflow.sleep(duration, summary:, cancellation: sleep_cancel)
              fiber.raise(exception_class, *exception_args) if fiber.alive?
            rescue Exception => e # rubocop:disable Lint/RescueException
              # Re-raise in fiber
              fiber.raise(e) if fiber.alive?
            end

            begin
              yield
            ensure
              sleep_cancel_proc.call
            end
          end

          def update_handlers
            @instance.update_handlers
          end

          def upsert_memo(hash)
            # Convert to memo, apply updates, then add the command (so command adding is post validation)
            upserted_memo = ProtoUtils.memo_to_proto(hash, payload_converter)
            memo._update do |new_hash|
              hash.each do |key, val|
                # Nil means delete
                if val.nil?
                  new_hash.delete(key.to_s)
                else
                  new_hash[key.to_s] = val
                end
              end
            end
            @instance.add_command(
              Bridge::Api::WorkflowCommands::WorkflowCommand.new(
                modify_workflow_properties: Bridge::Api::WorkflowCommands::ModifyWorkflowProperties.new(
                  upserted_memo:
                )
              )
            )
          end

          def upsert_search_attributes(*updates)
            # Apply updates then add the command (so command adding is post validation)
            search_attributes._disable_mutations = false
            search_attributes.update!(*updates)
            @instance.add_command(
              Bridge::Api::WorkflowCommands::WorkflowCommand.new(
                upsert_workflow_search_attributes: Bridge::Api::WorkflowCommands::UpsertWorkflowSearchAttributes.new(
                  search_attributes: updates.to_h(&:_to_proto_pair)
                )
              )
            )
          ensure
            search_attributes._disable_mutations = true
          end

          def wait_condition(cancellation:, &)
            @instance.scheduler.wait_condition(cancellation:, &)
          end

          def _outbound=(outbound)
            @outbound = outbound
          end
        end

        # TODO(cretz): Pull this out of this file
        class InboundImplementation < Temporalio::Worker::Interceptor::Workflow::Inbound
          def initialize(instance)
            super(nil) # steep:ignore
            @instance = instance
          end

          def init(outbound)
            @instance.context._outbound = outbound
          end

          def execute(input)
            @instance.instance.execute(*input.args)
          end

          def handle_signal(input)
            invoke_handler(input.signal, input)
          end

          def handle_query(input)
            invoke_handler(input.query, input)
          end

          def validate_update(input)
            invoke_handler(input.update, input, to_invoke: input.definition.validator_to_invoke)
          end

          def handle_update(input)
            invoke_handler(input.update, input)
          end

          private

          def invoke_handler(name, input, to_invoke: input.definition.to_invoke)
            args = input.args
            # Add name as first param if dynamic
            args = [name] + args if input.definition.name.nil?
            # Assume symbol or proc
            case to_invoke
            when Symbol
              @instance.instance.send(to_invoke, *args)
            when Proc
              to_invoke.call(*args)
            else
              raise "Unrecognized invocation type #{to_invoke.class}"
            end
          end
        end

        # TODO(cretz): Pull this out of this file
        class OutboundImplementation < Temporalio::Worker::Interceptor::Workflow::Outbound
          def initialize(instance)
            super(nil) # steep:ignore
            @instance = instance
            @activity_counter = 0
            @timer_counter = 0
            @child_counter = 0
          end

          def execute_activity(input)
            if input.schedule_to_close_timeout.nil? && input.start_to_close_timeout.nil?
              raise ArgumentError, 'Activity must have schedule_to_close_timeout or start_to_close_timeout'
            end

            activity_type = case input.activity
                            when Class
                              Activity::Definition::Info.from_activity(input.activity).name
                            when Symbol, String
                              input.activity.to_s
                            else
                              raise ArgumentError, 'Activity must be a definition class, or a symbol/string'
                            end
            execute_activity_with_local_backoffs(local: false, cancellation: input.cancellation) do
              seq = (@activity_counter += 1)
              @instance.add_command(
                Bridge::Api::WorkflowCommands::WorkflowCommand.new(
                  schedule_activity: Bridge::Api::WorkflowCommands::ScheduleActivity.new(
                    seq:,
                    activity_id: input.activity_id || seq.to_s,
                    activity_type:,
                    task_queue: input.task_queue,
                    headers: ProtoUtils.headers_to_proto(input.headers, @instance.payload_converter),
                    arguments: ProtoUtils.convert_to_payload_array(@instance.payload_converter, input.args),
                    schedule_to_close_timeout: ProtoUtils.seconds_to_duration(input.schedule_to_close_timeout),
                    schedule_to_start_timeout: ProtoUtils.seconds_to_duration(input.schedule_to_start_timeout),
                    start_to_close_timeout: ProtoUtils.seconds_to_duration(input.start_to_close_timeout),
                    heartbeat_timeout: ProtoUtils.seconds_to_duration(input.heartbeat_timeout),
                    retry_policy: input.retry_policy&._to_proto,
                    cancellation_type: input.cancellation_type,
                    do_not_eagerly_execute: input.disable_eager_execution
                  )
                )
              )
              seq
            end
          end

          def execute_local_activity(input)
            if input.schedule_to_close_timeout.nil? && input.start_to_close_timeout.nil?
              raise ArgumentError, 'Activity must have schedule_to_close_timeout or start_to_close_timeout'
            end

            activity_type = case input.activity
                            when Class
                              Activity::Definition::Info.from_activity(input.activity).name
                            when Symbol, String
                              input.activity.to_s
                            else
                              raise ArgumentError, 'Activity must be a definition class, or a symbol/string'
                            end
            execute_activity_with_local_backoffs(local: true, cancellation: input.cancellation) do |do_backoff|
              seq = (@activity_counter += 1)
              @instance.add_command(
                Bridge::Api::WorkflowCommands::WorkflowCommand.new(
                  schedule_local_activity: Bridge::Api::WorkflowCommands::ScheduleLocalActivity.new(
                    seq:,
                    activity_id: input.activity_id || seq.to_s,
                    activity_type:,
                    headers: ProtoUtils.headers_to_proto(input.headers, @instance.payload_converter),
                    arguments: ProtoUtils.convert_to_payload_array(@instance.payload_converter, input.args),
                    schedule_to_close_timeout: ProtoUtils.seconds_to_duration(input.schedule_to_close_timeout),
                    schedule_to_start_timeout: ProtoUtils.seconds_to_duration(input.schedule_to_start_timeout),
                    start_to_close_timeout: ProtoUtils.seconds_to_duration(input.start_to_close_timeout),
                    retry_policy: input.retry_policy&._to_proto,
                    cancellation_type: input.cancellation_type,
                    local_retry_threshold: ProtoUtils.seconds_to_duration(input.local_retry_threshold),
                    attempt: do_backoff&.attempt || 0,
                    original_schedule_time: do_backoff&.original_schedule_time
                  )
                )
              )
              seq
            end
          end

          def execute_activity_with_local_backoffs(local:, cancellation:, &)
            # We do not even want to schedule if the cancellation is already cancelled. We choose to use canceled
            # failure instead of wrapping in activity failure which is similar to what other SDKs do, with the accepted
            # tradeoff that it makes rescue more difficult (hence the presence of Error.canceled? helper).
            raise Error::CanceledError, 'Activity canceled before scheduled' if cancellation.canceled?

            # This has to be done in a loop for local activity backoff
            last_local_backoff = nil
            loop do
              result = execute_activity_once(local:, cancellation:, last_local_backoff:, &)
              return result unless result.is_a?(Bridge::Api::ActivityResult::DoBackoff)

              last_local_backoff = result
            end
          end

          # If this doesn't raise, it returns success | DoBackoff
          def execute_activity_once(local:, cancellation:, last_local_backoff:, &)
            # Add to pending activities (removed by the resolver)
            seq = yield last_local_backoff
            @instance.pending_activities[seq] = Fiber.current

            # Add cancellation hook
            cancel_callback_key = cancellation.add_cancel_callback do
              # Only if the activity is present still
              if @instance.pending_activities.include?(seq)
                if local
                  @instance.add_command(
                    Bridge::Api::WorkflowCommands::WorkflowCommand.new(
                      request_cancel_local_activity: Bridge::Api::WorkflowCommands::RequestCancelLocalActivity.new(seq:)
                    )
                  )
                else
                  @instance.add_command(
                    Bridge::Api::WorkflowCommands::WorkflowCommand.new(
                      request_cancel_activity: Bridge::Api::WorkflowCommands::RequestCancelActivity.new(seq:)
                    )
                  )
                end
              end
            end

            # Wait
            resolution = Fiber.yield

            # Remove cancellation callback
            cancellation.remove_cancel_callback(cancel_callback_key)

            case resolution.status
            when :completed
              @instance.payload_converter.from_payload(resolution.completed.result)
            when :failed
              raise @instance.failure_converter.from_failure(resolution.failed.failure, @instance.payload_converter)
            when :cancelled
              raise @instance.failure_converter.from_failure(resolution.cancelled.failure, @instance.payload_converter)
            when :backoff
              resolution.backoff
            else
              raise "Unrecognized resolution status: #{resolution.status}"
            end
          end

          def initialize_continue_as_new_error(input)
            # Do nothing
          end

          def sleep(input)
            # If already cancelled, raise as such
            if input.cancellation.canceled?
              raise Error::CanceledError,
                    input.cancellation.canceled_reason || 'Timer canceled before started'
            end

            # Disallow negative durations
            raise ArgumentError, 'Sleep duration cannot be less than 0' if input.duration&.negative?

            # If the duration is infinite, just wait for cancellation
            if input.duration.nil? || input.duration.zero?
              input.cancellation.wait
              raise Error::CanceledError, input.cancellation.canceled_reason || 'Timer canceled'
            end

            # Add command
            seq = (@timer_counter += 1)
            @instance.add_command(
              Bridge::Api::WorkflowCommands::WorkflowCommand.new(
                start_timer: Bridge::Api::WorkflowCommands::StartTimer.new(
                  seq:,
                  start_to_fire_timeout: ProtoUtils.seconds_to_duration(input.duration)
                )
              )
            )
            @instance.pending_timers[seq] = Fiber.current

            # Add a cancellation callback
            cancel_callback_key = input.cancellation.add_cancel_callback do
              # Only if the timer is still present
              fiber = @instance.pending_timers.delete(seq)
              if fiber
                # Add the command for cancel then raise
                @instance.add_command(
                  Bridge::Api::WorkflowCommands::WorkflowCommand.new(
                    cancel_timer: Bridge::Api::WorkflowCommands::CancelTimer.new(seq:)
                  )
                )
                if fiber.alive?
                  fiber.raise(Error::CanceledError.new(input.cancellation.canceled_reason || 'Timer canceled'))
                end
              end
            end

            # Wait
            Fiber.yield

            # Remove cancellation callback (only needed on success)
            input.cancellation.remove_cancel_callback(cancel_callback_key)
          end

          def start_child_workflow(input)
            # See execute_activity_with_local_backoffs below for why we are choosing CanceledError
            raise Error::CanceledError, 'Child canceled before scheduled' if input.cancellation.canceled?

            # Add the command
            seq = (@child_counter += 1)
            @instance.add_command(
              Bridge::Api::WorkflowCommands::WorkflowCommand.new(
                start_child_workflow_execution: Bridge::Api::WorkflowCommands::StartChildWorkflowExecution.new(
                  seq:,
                  namespace: @instance.info.namespace,
                  workflow_id: input.id,
                  workflow_type: case input.workflow
                                 when Class
                                   unless input.workflow < Workflow::Definition
                                     raise ArgumentError,
                                           "Class '#{input.workflow}' does not extend Temporalio::Workflow::Definition"
                                   end
                                   info = Workflow::Definition::Info.from_class(input.workflow)
                                   info.name || raise(ArgumentError, 'Cannot pass dynamic workflow to start')
                                 when Workflow::Definition::Info
                                   input.workflow.name || raise(ArgumentError, 'Cannot pass dynamic workflow to start')
                                 when String, Symbol
                                   input.workflow.to_s
                                 else
                                   raise ArgumentError, 'Workflow is not a workflow class or string/symbol'
                                 end,
                  task_queue: input.task_queue,
                  input: ProtoUtils.convert_to_payload_array(@instance.payload_converter, input.args),
                  workflow_execution_timeout: ProtoUtils.seconds_to_duration(input.execution_timeout),
                  workflow_run_timeout: ProtoUtils.seconds_to_duration(input.run_timeout),
                  workflow_task_timeout: ProtoUtils.seconds_to_duration(input.task_timeout),
                  parent_close_policy: input.parent_close_policy,
                  workflow_id_reuse_policy: input.id_reuse_policy,
                  retry_policy: input.retry_policy&._to_proto,
                  cron_schedule: input.cron_schedule,
                  headers: ProtoUtils.headers_to_proto(input.headers, @instance.payload_converter),
                  memo: ProtoUtils.memo_to_proto(input.memo, @instance.payload_converter),
                  search_attributes: input.search_attributes&._to_proto_hash,
                  cancellation_type: input.cancellation_type
                )
              )
            )

            # Set as pending start and register cancel callback
            @instance.pending_child_workflow_starts[seq] = Fiber.current
            cancel_callback_key = input.cancellation.add_cancel_callback do
              # Send cancel if in start or pending
              if @instance.pending_child_workflow_starts.include?(seq) ||
                 @instance.pending_child_workflows.include?(seq)
                @instance.add_command(
                  Bridge::Api::WorkflowCommands::WorkflowCommand.new(
                    cancel_child_workflow_execution: Bridge::Api::WorkflowCommands::CancelChildWorkflowExecution.new(
                      child_workflow_seq: seq
                    )
                  )
                )
              end
            end

            # Wait for start
            resolution = Fiber.yield

            case resolution.status
            when :succeeded
              # Create handle, passing along the cancel callback key, and set it as pending
              handle = ChildWorkflowHandle.new(
                id: input.id,
                first_execution_run_id: resolution.succeeded.run_id,
                instance: @instance,
                cancellation: input.cancellation,
                cancel_callback_key:
              )
              @instance.pending_child_workflows[seq] = handle
              handle
            when :failed
              # Remove cancel callback and handle failure
              input.cancellation.remove_cancel_callback(cancel_callback_key)
              if resolution.failed.cause == Bridge::Api::ChildWorkflow::StartChildWorkflowExecutionFailedCause::
                  START_CHILD_WORKFLOW_EXECUTION_FAILED_CAUSE_WORKFLOW_ALREADY_EXISTS
                raise Error::WorkflowAlreadyStartedError.new(
                  workflow_id: resolution.failed.workflow_id,
                  workflow_type: resolution.failed.workflow_type,
                  run_id: nil
                )
              end
              raise "Unknown child start fail cause: #{resolution.failed.cause}"
            when :cancelled
              # Remove cancel callback and handle cancel
              input.cancellation.remove_cancel_callback(cancel_callback_key)
              raise @instance.failure_converter.from_failure(resolution.cancelled.failure, @instance.payload_converter)
            end
          end
        end

        # TODO(cretz): Pull this out of this file
        class Scheduler
          def initialize(instance)
            @instance = instance
            @fibers = []
            @ready = []
            @wait_conditions = {}
            @wait_condition_counter = 0
          end

          def context
            @instance.context
          end

          def run_until_all_yielded
            loop do
              # Rub all fibers until all yielded
              while (fiber = @ready.shift)
                fiber.resume
              end

              # Find the _first_ resolvable wait condition and if there, resolve
              # it, and loop again, otherwise return. It is important that we
              # both let fibers get all settled _before_ this and only allow a
              # _single_ wait condition to be satisfied before looping. This
              # allows wait condition users to trust that the line of code after
              # the wait condition still has the condition satisfied.
              cond_fiber = nil
              cond_result = nil
              @wait_conditions.each do |seq, cond|
                next unless (cond_result = cond.first.call)

                cond_fiber = cond[1]
                @wait_conditions.delete(seq)
                break
              end
              return if cond_fiber.nil?

              cond_fiber.resume(cond_result)
            end
          end

          def wait_condition(cancellation:, &block)
            if cancellation&.canceled?
              raise Error::CanceledError,
                    cancellation.canceled_reason || 'Wait condition canceled before started'
            end

            seq = (@wait_condition_counter += 1)
            @wait_conditions[seq] = [block, Fiber.current]

            # Add a cancellation callback
            cancel_callback_key = cancellation&.add_cancel_callback do
              # Only if the condition is still present
              cond = @wait_conditions.delete(seq)
              if cond&.last&.alive?
                cond&.last&.raise(Error::CanceledError.new(cancellation.canceled_reason || 'Wait condition canceled'))
              end
            end

            # This blocks until a resume is called on this fiber
            result = Fiber.yield

            # Remove cancellation callback (only needed on success)
            cancellation&.remove_cancel_callback(cancel_callback_key)

            result
          end

          def stack_trace
            # Collect backtraces of known fibers, separating with a blank line. We make sure to remove any lines that
            # reference Temporal paths, and we remove any empty backtraces.
            dir_path = @instance.illegal_call_tracing_disabled { File.dirname(Temporalio._root_file_path) }
            @fibers.map do |fiber|
              fiber.backtrace.reject { |s| s.start_with?(dir_path) }.join("\n")
            end.reject(&:empty?).join("\n\n")
          end

          ###
          # Fiber::Scheduler methods
          #
          # Note, we do not implement many methods here such as io_read and
          # such. While it might seem to make sense to implement them and
          # raise, we actually want to default to the blocking behavior of them
          # not being present. This is so advanced things like logging still
          # work inside of workflows. So we only implement the bare minimum.
          ###

          def block(_blocker, timeout = nil)
            # TODO(cretz): Do we want to support block with timeout?
            raise NotImplementedError, 'Cannot block with timeouts in workflows' if timeout

            true
          end

          def close
            # Nothing to do here, lifetime of scheduler is controlled by the instance
          end

          def fiber(&block)
            fiber = Fiber.new do
              block.call
            ensure
              @fibers.delete(Fiber.current)
            end
            @fibers << fiber
            @ready << fiber
            fiber
          end

          def io_wait(io, events, timeout)
            # TODO(cretz): This in a blocking fashion?
            raise NotImplementedError, 'TODO'
          end

          def kernel_sleep(duration = nil)
            Workflow.sleep(duration)
          end

          def process_wait(pid, flags)
            raise NotImplementedError, 'Cannot wait on other processes in workflows'
          end

          def timeout_after(duration, exception_class, *exception_arguments, &)
            context.timeout(duration, exception_class, *exception_arguments, summary: 'Timeout timer', &)
          end

          def unblock(_blocker, fiber)
            @ready << fiber
          end
        end

        # TODO(cretz): Pull this out of this file
        class Details
          attr_reader :namespace, :task_queue, :definition, :initial_activation, :logger, :payload_converter,
                      :failure_converter, :interceptors, :disable_eager_activity_execution, :illegal_calls,
                      :workflow_failure_exception_types

          def initialize(
            namespace:,
            task_queue:,
            definition:,
            initial_activation:,
            logger:,
            payload_converter:,
            failure_converter:,
            interceptors:,
            disable_eager_activity_execution:,
            illegal_calls:,
            workflow_failure_exception_types:
          )
            @namespace = namespace
            @task_queue = task_queue
            @definition = definition
            @initial_activation = initial_activation
            @logger = logger
            @payload_converter = payload_converter
            @failure_converter = failure_converter
            @interceptors = interceptors
            @disable_eager_activity_execution = disable_eager_activity_execution
            @illegal_calls = illegal_calls
            @workflow_failure_exception_types = workflow_failure_exception_types
          end
        end

        # TODO(cretz): Pull this out of this file
        class IllegalCallTracer
          def self.frozen_validated_illegal_calls(illegal_calls)
            illegal_calls.to_h do |key, val|
              raise TypeError, 'Invalid illegal call map, top-level key must be a String' unless key.is_a?(String)

              fixed_val = case val
                          when Array
                            val.to_h do |sub_val|
                              unless sub_val.is_a?(Symbol)
                                raise TypeError,
                                      'Invalid illegal call map, each value must be a Symbol'
                              end

                              [sub_val, true]
                            end.freeze
                          when :all
                            :all
                          else
                            raise TypeError, 'Invalid illegal call map, top-level value must be an Array or :all'
                          end

              [key.frozen? ? key : key.dup.freeze, fixed_val]
            end.freeze
          end

          # Illegal calls are Hash[String, Hash[Symbol, Bool]]
          def initialize(illegal_calls)
            @tracepoint = TracePoint.new(:call, :c_call) do |tp|
              cls = tp.defined_class
              next unless cls.is_a?(Module)

              if cls.singleton_class?
                cls = cls.attached_object
                next unless cls.is_a?(Module)
              end
              vals = illegal_calls[cls.name]
              if vals == :all || vals&.[](tp.callee_id)
                raise Workflow::NondeterminismError,
                      "Cannot access #{cls.name} #{tp.callee_id} from inside a " \
                      'workflow. If this is known to be safe, the code can be run in ' \
                      'a Temporalio::Workflow::Unsafe.illegal_call_tracing_disabled block.'
              end
            end
          end

          def enable(&)
            @tracepoint.enable(&)
          end

          def disable(&)
            @tracepoint.disable(&)
          end
        end

        # TODO(cretz): Pull this out of this file
        class HandlerHash < SimpleDelegator
          def initialize(initial_frozen_hash, definition_class, &on_new_definition)
            super(initial_frozen_hash)
            @definition_class = definition_class
            @on_new_definition = on_new_definition
          end

          def []=(name, definition)
            store(name, definition)
          end

          def store(name, definition)
            raise ArgumentError, 'Name must be a string or nil' unless name.nil? || name.is_a?(String)

            unless definition.nil? || definition.is_a?(@definition_class)
              raise ArgumentError,
                    "Value must be a #{@definition_class.name} or nil"
            end
            raise ArgumentError, 'Name does not match one in definition' if definition && name != definition.name

            # Do a copy-on-write op on the underlying frozen hash
            new_hash = __getobj__.dup
            new_hash[name] = definition
            __setobj__(new_hash.freeze)
            @on_new_definition&.call(definition) unless definition.nil?
          end
        end

        # TODO(cretz): Pull this out of this file
        class ExternallyImmutableHash < SimpleDelegator
          def initialize(initial_hash)
            super(initial_hash.freeze)
          end

          def _update(&)
            new_hash = __getobj__.dup
            yield new_hash
            __setobj__(new_hash.freeze)
          end
        end

        # TODO(cretz): Pull this out of this file
        class ChildWorkflowHandle < Workflow::ChildWorkflowHandle
          attr_reader :id, :first_execution_run_id

          def initialize(id:, first_execution_run_id:, instance:, cancellation:, cancel_callback_key:) # rubocop:disable Lint/MissingSuper
            @id = id
            @first_execution_run_id = first_execution_run_id
            @instance = instance
            @cancellation = cancellation
            @cancel_callback_key = cancel_callback_key
            @resolution = nil
          end

          def result
            # Notice that we actually provide a detached cancellation here instead of defaulting to workflow
            # cancellation because we don't want workflow cancellation (or a user-provided cancellation to this result
            # call) to be able to interrupt waiting on a child that may be processing the cancellation.
            Workflow.wait_condition(cancellation: Cancellation.new) { @resolution }

            case @resolution.status
            when :completed
              @instance.payload_converter.from_payload(@resolution.completed.result)
            when :failed
              raise @instance.failure_converter.from_failure(@resolution.failed.failure, @instance.payload_converter)
            when :cancelled
              raise @instance.failure_converter.from_failure(@resolution.cancelled.failure, @instance.payload_converter)
            else
              raise "Unrecognized resolution status: #{@resolution.status}"
            end
          end

          def _resolve(resolution)
            @cancellation.remove_cancel_callback(@cancel_callback_key)
            @resolution = resolution
          end
        end

        class ReplaySafeLogger < ScopedLogger
          def initialize(logger:, instance:)
            @instance = instance
            @replay_safety_disabled = false
            super(logger)
          end

          def replay_safety_disabled(&)
            @replay_safety_disabled = true
            yield
          ensure
            @replay_safety_disabled = false
          end

          def add(...)
            if !@replay_safety_disabled && Temporalio::Workflow.in_workflow? && Temporalio::Workflow::Unsafe.replaying?
              return
            end

            # Disable illegal call tracing for the log call
            @instance.illegal_call_tracing_disabled { super }
          end
        end
      end
    end
  end
end

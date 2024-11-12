# frozen_string_literal: true

require 'temporalio'
require 'temporalio/activity/definition'
require 'temporalio/api'
require 'temporalio/converters/raw_value'
require 'temporalio/error'
require 'temporalio/internal/bridge/api'
require 'temporalio/internal/proto_utils'
require 'temporalio/internal/worker/workflow_instance/child_workflow_handle'
require 'temporalio/internal/worker/workflow_instance/context'
require 'temporalio/internal/worker/workflow_instance/details'
require 'temporalio/internal/worker/workflow_instance/externally_immutable_hash'
require 'temporalio/internal/worker/workflow_instance/handler_hash'
require 'temporalio/internal/worker/workflow_instance/illegal_call_tracer'
require 'temporalio/internal/worker/workflow_instance/inbound_implementation'
require 'temporalio/internal/worker/workflow_instance/outbound_implementation'
require 'temporalio/internal/worker/workflow_instance/replay_safe_logger'
require 'temporalio/internal/worker/workflow_instance/scheduler'
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
          @search_attributes ||= SearchAttributes._from_proto(
            @init_job.search_attributes, disable_mutations: true, never_nil: true
          )
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
          defn = signal_handlers[job.signal_name] || signal_handlers[nil]
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
                    @logger.error("Failed converting signal input arguments for #{job.signal_name}, dropping signal")
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
          # TODO(cretz): __temporal_workflow_metadata
          defn = case job.query_type
                 when '__stack_trace'
                   Workflow::Definition::Query.new(
                     name: '__stack_trace',
                     to_invoke: proc { scheduler.stack_trace }
                   )
                 else
                   query_handlers[job.query_type] || query_handlers[nil]
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
          defn = update_handlers[job.name] || update_handlers[nil]
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
            req_count = 0
            @definition.workflow_class.instance_method(method_name).parameters.each do |(type, _)|
              if type == :rest
                count = nil
                break
              elsif %i[req opt].include?(type)
                count += 1
                req_count += 1 if type == :req
              end
            end
            # Fail if too few required param values, trim off excess if too many. If count is nil, it has a splat.
            if count
              if ignore_first_param
                count -= 1
                req_count -= 1
              end
              if req_count > payload_array.size
                # We have to fail here instead of let Ruby fail the invocation because some handlers, such as signals,
                # want to log and ignore invalid arguments instead of fail and if we used Ruby failure, we can't
                # differentiate between too-few-param caused by us or somewhere else by a user.
                raise ArgumentError, "wrong number of required arguments for #{method_name} " \
                                     "(given #{payload_array.size}, expected #{req_count})"
              end
              payload_array = payload_array.take(count)
            end
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
      end
    end
  end
end

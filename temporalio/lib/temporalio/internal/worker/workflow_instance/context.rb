# frozen_string_literal: true

require 'temporalio/cancellation'
require 'temporalio/error'
require 'temporalio/internal/bridge/api'
require 'temporalio/internal/proto_utils'
require 'temporalio/internal/worker/workflow_instance'
require 'temporalio/worker/interceptor'
require 'temporalio/workflow'

module Temporalio
  module Internal
    module Worker
      class WorkflowInstance
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
      end
    end
  end
end

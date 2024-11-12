# frozen_string_literal: true

module Temporalio
  class Worker
    module Interceptor
      # Mixin for intercepting activity worker work. Clases that `include` may implement their own {intercept_activity}
      # that returns their own instance of {Inbound}.
      #
      # @note Input classes herein may get new required fields added and therefore the constructors of the Input classes
      #   may change in backwards incompatible ways. Users should not try to construct Input classes themselves.
      module Activity
        # Method called when intercepting an activity. This is called when starting an activity attempt.
        #
        # @param next_interceptor [ActivityInbound] Next interceptor in the chain that should be called. This is usually
        #   passed to {ActivityInbound} constructor.
        # @return [ActivityInbound] Interceptor to be called for activity calls.
        def intercept(next_interceptor)
          next_interceptor
        end

        # Input for {Inbound.execute}.
        ExecuteInput = Struct.new(
          :proc,
          :args,
          :headers,
          keyword_init: true
        )

        # Inbound interceptor for intercepting inbound activity calls. This should be extended by users needing to
        # intercept activities.
        class Inbound
          # @return [Inbound] Next interceptor in the chain.
          attr_reader :next_interceptor

          # Initialize inbound with the next interceptor in the chain.
          #
          # @param next_interceptor [Inbound] Next interceptor in the chain.
          def initialize(next_interceptor)
            @next_interceptor = next_interceptor
          end

          # Initialize the outbound interceptor. This should be extended by users to return their own {Outbound}
          # implementation that wraps the parameter here.
          #
          # @param outbound [Outbound] Next outbound interceptor in the chain.
          # @return [Outbound] Outbound activity interceptor.
          def init(outbound)
            @next_interceptor.init(outbound)
          end

          # Execute an activity and return result or raise exception. Next interceptor in chain (i.e. `super`) will
          # perform the execution.
          #
          # @param input [ExecuteInput] Input information.
          # @return [Object] Activity result.
          def execute(input)
            @next_interceptor.execute(input)
          end
        end

        # Input for {Outbound.heartbeat}.
        HeartbeatInput = Struct.new(
          :details,
          keyword_init: true
        )

        # Outbound interceptor for intercepting outbound activity calls. This should be extended by users needing to
        # intercept activity calls.
        class Outbound
          # @return [Outbound] Next interceptor in the chain.
          attr_reader :next_interceptor

          # Initialize outbound with the next interceptor in the chain.
          #
          # @param next_interceptor [Outbound] Next interceptor in the chain.
          def initialize(next_interceptor)
            @next_interceptor = next_interceptor
          end

          # Issue a heartbeat.
          #
          # @param input [HeartbeatInput] Input information.
          def heartbeat(input)
            @next_interceptor.heartbeat(input)
          end
        end
      end

      module Workflow
        ExecuteInput = Struct.new(
          :args,
          :headers,
          keyword_init: true
        )

        HandleSignalInput = Struct.new(
          :signal,
          :args,
          :definition,
          :headers,
          keyword_init: true
        )

        HandleQueryInput = Struct.new(
          :id,
          :query,
          :args,
          :definition,
          :headers,
          keyword_init: true
        )

        HandleUpdateInput = Struct.new(
          :id,
          :update,
          :args,
          :definition,
          :headers,
          keyword_init: true
        )

        class Inbound
          attr_reader :next_interceptor

          def initialize(next_interceptor)
            @next_interceptor = next_interceptor
          end

          def init(outbound)
            @next_interceptor.init(outbound)
          end

          def execute(input)
            @next_interceptor.execute(input)
          end

          def handle_signal(input)
            @next_interceptor.handle_signal(input)
          end

          def handle_query(input)
            @next_interceptor.handle_query(input)
          end

          def validate_update(input)
            @next_interceptor.validate_update(input)
          end

          def handle_update(input)
            @next_interceptor.handle_update(input)
          end
        end

        ExecuteActivityInput = Struct.new(
          :activity,
          :args,
          :task_queue,
          :schedule_to_close_timeout,
          :schedule_to_start_timeout,
          :start_to_close_timeout,
          :heartbeat_timeout,
          :retry_policy,
          :cancellation,
          :cancellation_type,
          :activity_id,
          :disable_eager_execution,
          :headers,
          keyword_init: true
        )

        ExecuteLocalActivityInput = Struct.new(
          :activity,
          :args,
          :schedule_to_close_timeout,
          :schedule_to_start_timeout,
          :start_to_close_timeout,
          :retry_policy,
          :local_retry_threshold,
          :cancellation,
          :cancellation_type,
          :activity_id,
          :headers,
          keyword_init: true
        )

        InitializeContinueAsNewErrorInput = Struct.new(
          :error,
          keyword_init: true
        )

        SleepInput = Struct.new(
          :duration,
          :summary,
          :cancellation
        )

        StartChildWorkflowInput = Struct.new(
          :workflow,
          :args,
          :id,
          :task_queue,
          :cancellation,
          :cancellation_type,
          :parent_close_policy,
          :execution_timeout,
          :run_timeout,
          :task_timeout,
          :id_reuse_policy,
          :retry_policy,
          :cron_schedule,
          :memo,
          :search_attributes,
          :headers,
          keyword_init: true
        )

        class Outbound
          attr_reader :next_interceptor

          def initialize(next_interceptor)
            @next_interceptor = next_interceptor
          end

          def execute_activity(input)
            @next_interceptor.execute_activity(input)
          end

          def execute_local_activity(input)
            @next_interceptor.execute_local_activity(input)
          end

          def initialize_continue_as_new_error(input)
            @next_interceptor.initialize_continue_as_new_error(input)
          end

          def sleep(input)
            @next_interceptor.sleep(input)
          end

          def start_child_workflow(input)
            @next_interceptor.start_child_workflow(input)
          end
        end
      end
    end
  end
end

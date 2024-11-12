# frozen_string_literal: true

require 'temporalio'
require 'temporalio/cancellation'
require 'temporalio/error'
require 'temporalio/internal/worker/workflow_instance'
require 'temporalio/workflow'

module Temporalio
  module Internal
    module Worker
      class WorkflowInstance
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
      end
    end
  end
end

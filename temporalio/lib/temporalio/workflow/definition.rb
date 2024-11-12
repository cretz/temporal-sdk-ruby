# frozen_string_literal: true

require 'temporalio/workflow'
require 'temporalio/workflow/handler_unfinished_policy'

module Temporalio
  module Workflow
    class Definition
      class << self
        protected

        def workflow_name(workflow_name)
          if !workflow_name.is_a?(Symbol) && !workflow_name.is_a?(String)
            raise ArgumentError,
                  'Workflow name must be a symbol or string'
          end

          @workflow_name = workflow_name.to_s
        end

        def workflow_dynamic(value = true)
          @workflow_dynamic = value
        end

        def workflow_raw_args(value = true)
          @workflow_raw_args = value
        end

        def workflow_failure_exception_type(*types)
          types.each do |t|
            raise ArgumentError, 'All types must classes inheriting Exception' unless t.is_a?(Class) && t < Exception
          end
          @workflow_failure_exception_types ||= []
          @workflow_failure_exception_types.concat(types)
        end

        def workflow_query_attr_reader(*attr_names)
          @workflow_queries ||= {}
          attr_names.each do |attr_name|
            raise 'Expected attr to be a symbol' unless attr_name.is_a?(Symbol)

            if method_defined?(attr_name, false)
              raise 'Method already defined for this attr name. ' \
                    'Note that a workflow_query_attr_reader includes attr_reader behavior. ' \
                    'If you also want a writer for this attribute, use a separate attr_writer.'
            end

            # Just run this as if done manually
            workflow_query
            define_method(attr_name) { instance_variable_get("@#{attr_name}") }
          end
        end

        def workflow_init(value = true)
          self.pending_handler_details = { type: :init, value: }
        end

        def workflow_signal(
          name: nil,
          dynamic: false,
          raw_args: false,
          unfinished_policy: HandlerUnfinishedPolicy::WARN_AND_ABANDON
        )
          raise 'Cannot provide name if dynamic is true' if name && dynamic

          self.pending_handler_details = { type: :signal, name:, dynamic:, raw_args:, unfinished_policy: }
        end

        def workflow_query(
          name: nil,
          dynamic: false,
          raw_args: false
        )
          raise 'Cannot provide name if dynamic is true' if name && dynamic

          self.pending_handler_details = { type: :query, name:, dynamic:, raw_args: }
        end

        def workflow_update(
          name: nil,
          dynamic: false,
          raw_args: false,
          unfinished_policy: HandlerUnfinishedPolicy::WARN_AND_ABANDON
        )
          raise 'Cannot provide name if dynamic is true' if name && dynamic

          self.pending_handler_details = { type: :update, name:, dynamic:, raw_args:, unfinished_policy: }
        end

        def workflow_update_validator(update_method)
          self.pending_handler_details = { type: :update_validator, update_method: }
        end

        private

        attr_reader :pending_handler_details

        def pending_handler_details=(value)
          if value.nil?
            @pending_handler_details = value
            return
          elsif @pending_handler_details
            raise "Previous #{@pending_handler_details[:type]} handler was not put on method before this handler"
          end

          @pending_handler_details = value
        end
      end

      def self.method_added(method_name)
        super

        # Nothing to do if there are no pending handler details
        handler = pending_handler_details
        return unless handler

        # Reset details
        self.pending_handler_details = nil

        # Initialize class variables if not done already
        @workflow_signals ||= {}
        @workflow_queries ||= {}
        @workflow_updates ||= {}
        @workflow_update_validators ||= {}
        @defined_methods ||= []

        defn, hash, other_hashes =
          case handler[:type]
          when :init
            raise "workflow_init was applied to #{method_name} instead of initialize" if method_name != :initialize

            @workflow_init = handler[:value]
            return
          when :update_validator
            other = @workflow_update_validators[handler[:update_method]]
            if other && (other[:method_name] != method_name || other[:update_method] != handler[:update_method])
              raise "Workflow update validator on #{method_name} for #{handler[:update_method]} defined separately " \
                    "on #{other[:method_name]} for #{other[:update_method]}"
            end

            # Just store this, we'll apply validators to updates at definition
            # building time
            @workflow_update_validators[handler[:update_method]] = { method_name:, **handler }
            return
          when :signal
            [Signal.new(
              name: handler[:dynamic] ? nil : (handler[:name] || method_name).to_s,
              to_invoke: method_name,
              raw_args: handler[:raw_args],
              unfinished_policy: handler[:unfinished_policy]
            ), @workflow_signals, [@workflow_queries, @workflow_updates]]
          when :query
            [Query.new(
              name: handler[:dynamic] ? nil : (handler[:name] || method_name).to_s,
              to_invoke: method_name,
              raw_args: handler[:raw_args]
            ), @workflow_queries, [@workflow_signals, @workflow_updates]]
          when :update
            [Update.new(
              name: handler[:dynamic] ? nil : (handler[:name] || method_name).to_s,
              to_invoke: method_name,
              raw_args: handler[:raw_args],
              unfinished_policy: handler[:unfinished_policy]
            ), @workflow_updates, [@workflow_signals, @workflow_queries]]
          else
            raise "Unrecognized handler type #{handler[:type]}"
          end

        # We only allow dupes with the same method name (override/redefine)
        # TODO(cretz): Should we also check that everything else is the same?
        other = hash[defn.name]
        if other && other.to_invoke != method_name
          raise "Workflow #{handler[:type].name} #{defn.name || '<dynamic>'} defined on " \
                "different methods #{other.to_invoke} and #{method_name}"
        elsif defn.name && other_hashes.any? { |h| h.include?(defn.name) }
          raise "Workflow signal #{defn.name} already defined as a different handler type"
        end
        hash[defn.name] = defn

        # Define class method for referencing the definition only if non-dynamic
        return unless defn.name

        define_singleton_method(method_name) { defn }
        @defined_methods.push(method_name)
      end

      def self.singleton_method_added(method_name)
        super
        # We need to ensure class methods are not added after we have defined a method
        return unless @defined_methods&.include?(method_name)

        raise 'Attempting to override Temporal-defined class definition method'
      end

      def self._workflow_definition
        @workflow_definition ||= _build_workflow_definition
      end

      def self._build_workflow_definition
        # Make sure there isn't dangling pending handler details
        raise "Leftover #{pending_handler_details[:type]} handler not applied to a method" if pending_handler_details

        # Apply all update validators before merging with super
        updates = @workflow_updates&.dup || {}
        @workflow_update_validators&.each_value do |validator|
          update = updates.values.find { |u| u.to_invoke == validator[:update_method] }
          unless update
            raise "Unable to find update #{validator[:update_method]} pointed to by " \
                  "validator on #{validator[:method_name]}"
          end
          if instance_method(validator[:method_name])&.parameters !=
             instance_method(validator[:update_method])&.parameters
            raise "Validator on #{validator[:method_name]} does not have " \
                  "exact parameter signature of #{validator[:update_method]}"
          end

          updates[update.name] = update.with_validator_to_invoke(validator[:method_name])
        end

        # If there is a superclass, apply some values and check others
        override_name = @workflow_name
        dynamic = @workflow_dynamic
        init = @workflow_init
        raw_args = @workflow_raw_args
        signals = @workflow_signals || {}
        queries = @workflow_queries || {}
        if superclass != Temporalio::Workflow::Definition
          super_info = superclass._workflow_definition

          # Override values if not set here
          override_name = super_info.override_name if override_name.nil?
          dynamic = super_info.dynamic if dynamic.nil?
          init = super_info.init if init.nil?
          raw_args = super_info.raw_args if raw_args.nil?

          # Make sure handlers on the same method at least have the same name
          # TODO(cretz): Need to validate any other handler override details?
          # Probably not because we only care that caller-needed values remain
          # unchanged (method and name), implementer-needed values can be
          # overridden/changed.
          self_handlers = signals.values + queries.values + updates.values
          super_handlers = super_info.signals.values + super_info.queries.values + super_info.updates.values
          super_handlers.each do |super_handler|
            self_handler = self_handlers.find { |h| h.to_invoke == super_handler.to_invoke }
            next unless self_handler

            if super_handler.class != self_handler.class
              raise "Superclass handler on #{self_handler.to_invoke} is a #{super_handler.class} " \
                    "but current class expects #{self_handler.class}"
            end
            if super_handler.name != self_handler.name
              raise "Superclass handler on #{self_handler.to_invoke} has name #{super_handler.name} " \
                    "but current class expects #{self_handler.name}"
            end
          end

          # Merge handlers. We will merge such that handlers defined here
          # override ones from superclass by _name_ (not method to invoke).
          signals = super_info.signals.merge(signals)
          queries = super_info.queries.merge(queries)
          updates = super_info.updates.merge(updates)
        end

        # If init is true, validate initialize and execute signatures are identical
        if init && instance_method(:initialize)&.parameters&.size != instance_method(:execute)&.parameters&.size
          raise 'workflow_init present, so parameter count of initialize and execute must be the same'
        end

        raise 'Workflow cannot be given a name and be dynamic' if dynamic && override_name

        Info.new(
          workflow_class: self,
          override_name:,
          dynamic: dynamic || false,
          init: init || false,
          raw_args: raw_args || false,
          failure_exception_types: @workflow_failure_exception_types || [],
          signals:,
          queries:,
          updates:
        )
      end

      def execute(*args)
        raise NotImplementedError, 'Workflow did not implement "execute"'
      end

      class Info
        attr_reader :workflow_class, :override_name, :dynamic, :init, :raw_args,
                    :failure_exception_types, :signals, :queries, :updates

        def self.from_class(workflow_class)
          unless workflow_class.is_a?(Class) && workflow_class < Definition
            raise "Workflow '#{workflow_class}' must be a class and must extend Temporalio::Workflow::Definition"
          end

          workflow_class._workflow_definition
        end

        def initialize(
          workflow_class:,
          override_name: nil,
          dynamic: false,
          init: false,
          raw_args: false,
          failure_exception_types: [],
          signals: {},
          queries: {},
          updates: {}
        )
          @workflow_class = workflow_class
          @override_name = override_name
          @dynamic = dynamic
          @init = init
          @raw_args = raw_args
          @failure_exception_types = failure_exception_types.dup.freeze
          @signals = signals.dup.freeze
          @queries = queries.dup.freeze
          @updates = updates.dup.freeze
        end

        def name
          dynamic ? nil : (override_name || workflow_class.name.to_s.split('::').last)
        end
      end

      class Signal
        attr_reader :name, :to_invoke, :raw_args, :unfinished_policy

        def initialize(
          name:,
          to_invoke:,
          raw_args: false,
          unfinished_policy: HandlerUnfinishedPolicy::WARN_AND_ABANDON
        )
          @name = name
          @to_invoke = to_invoke
          @raw_args = raw_args
          @unfinished_policy = unfinished_policy
        end
      end

      class Query
        attr_reader :name, :to_invoke, :raw_args

        def initialize(
          name:,
          to_invoke:,
          raw_args: false
        )
          @name = name
          @to_invoke = to_invoke
          @raw_args = raw_args
        end
      end

      class Update
        attr_reader :name, :to_invoke, :raw_args, :unfinished_policy, :validator_to_invoke

        def initialize(
          name:,
          to_invoke:,
          raw_args: false,
          unfinished_policy: HandlerUnfinishedPolicy::WARN_AND_ABANDON,
          validator_to_invoke: nil
        )
          @name = name
          @to_invoke = to_invoke
          @raw_args = raw_args
          @unfinished_policy = unfinished_policy
          @validator_to_invoke = validator_to_invoke
        end

        def with_validator_to_invoke(validator_to_invoke)
          Update.new(
            name:,
            to_invoke:,
            raw_args:,
            unfinished_policy:,
            validator_to_invoke:
          )
        end
      end
    end
  end
end

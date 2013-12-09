require 'active_support/concern'
require 'active_support/notifications'

module Controllers
  # Allows the controller to fire ActiveSupport notification events each time an action method is invoked.
  module Instrumentation
    extend ActiveSupport::Concern

    # Hooks into ActionController::Instrumentation's api to add custom information to the action event's payload.
    # Adds the current user (as +user+), if any, and the request to the payload. Evaluates the payload customizations
    # applicable to the invoked action method. If one of them is a Skip, ignores all other customizations.
    def append_info_to_payload(payload)
      payload[:user] = current_user if respond_to?(:current_user) && current_user.present?
      payload[:request] = request
      customizations = self.class.applicable_payload_customizations(action_name)
      skip = customizations.detect {|c| c.is_a?(Skip)}
      customizations = [skip] if skip
      customizations.each {|c| c.append_info_to_payload(payload, self)}
    end

    module ClassMethods
      def payload_customizations
        @payload_customizations ||= []
      end

      def applicable_payload_customizations(action_name)
        payload_customizations.find_all {|c| c.applicable_to?(action_name)}
      end

      # Specifies customizations of the payload of an action event.
      #
      # Examples:
      #
      # Add entire invite:
      #   customize_action_event variables: [:invite]
      # Add inviter and invitee ids only:
      #   customize_action_event variables: [{:invite => :invitee_id}, {:invite => :inviter_id}]
      # Add parameter:
      #   customize_action_event params: [:id]
      #
      # @param [Hash] options
      # @option options [Array] +only+ the customization is applicable only to these actions
      # @option options [Array] +except+ the customization is applicable to all actions except these
      # @option options [Array] +variables+ instance variables to include in the payload. each element of the array can
      #   either be a Symbol representing a instance variable whose value is to be added to the payload under that
      #   name, or a Hash whose Symbol key represents an instance variable and whose Symbol value represents a method
      #   to call on that instance variable, the return value of which is to be added to the payload under that name
      # @option options [Array] +params+ request params to include in the payload
      def customize_action_event(options = {})
        payload_customizations << Vars.new(options) if options[:variables]
        payload_customizations << Params.new(options) if options[:params]
      end

      # Specifies that no action event should be fired.
      #
      # @param [Hash] options
      # @option options [Array] +only+ the customization is applicable only to these actions
      # @option options [Array] +except+ the customization is applicable to all actions except these
      def skip_action_event(options = {})
        payload_customizations << Skip.new(options)
      end
    end

    class Customization
      attr_reader :only, :except

      def initialize(options = {})
        @only = Array(options.fetch(:only, [])).map(&:to_sym)
        @except = Array(options.fetch(:except, [])).map(&:to_sym)
      end

      def applicable_to?(action)
        return false if except.any? and action.to_sym.in?(except)
        return false if only.any? and not action.to_sym.in?(only)
        true
      end
    end

    class Vars < Customization
      attr_reader :variables

      def initialize(options = {})
        super(options)
        @variables = Array(options.fetch(:variables, []))
      end

      def append_info_to_payload(payload, controller)
        variables.each do |v|
          if v.is_a?(Hash)
            v.each do |k, v|
              iv = controller.instance_variable_get("@#{k}")
              payload[v] = iv.send(v) if iv
            end
          else
            payload[v] = controller.instance_variable_get("@#{v}")
          end
        end
      end
    end

    class Params < Customization
      attr_reader :params

      def initialize(options = {})
        super(options)
        @params = Array(options.fetch(:params, []))
      end

      def append_info_to_payload(payload, controller)
        params.each do |p|
          payload[p] = controller.params[p.to_s]
        end
      end
    end

    class Skip < Customization
      def append_info_to_payload(payload, controller)
        payload[:skip] = true
      end
    end
  end
end

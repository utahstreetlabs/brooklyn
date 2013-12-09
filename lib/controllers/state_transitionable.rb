module Controllers
  # Provides utilities for handling state machine transitions
  module StateTransitionable
    extend ActiveSupport::Concern

    module InstanceMethods
      def handle_state_transition_error(record, transition, opts={})
        m = "Error in state transition! #{record.class.name} #{record.id} had errors: #{record.errors} #{'additionally, ' + opts[:msg] if opts[:msg]}"
        logger.error(m)
        notify_airbrake(error_class: state_transition_error_class(transition), error_message: m, parameters: {errors: record.errors}) unless opts[:skip_airbrake]
        set_flash_message(:error, :"#{transition}_failed", support: support_email) unless opts[:noflash]
      end

      def state_transition_error_class(transition)
        "#{params[:controller]}_#{params[:action]}_#{transition}".camelize
      end

      def support_email
        view_context.mail_to Brooklyn::Application.config.email.to.help
      end
    end
  end
end

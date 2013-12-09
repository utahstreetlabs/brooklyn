module Notifications
  # Base class for exhibits that render notifications
  class BaseExhibit < Exhibitionist::Exhibit
    def render_notification(options = {})
      context.content_tag(:div, data: {target: options[:target]}) do
        out = []
        out << context.content_tag(:div, data: {role: 'notification-actor-image'},
                                   class: 'notification-actor-image-container') do
          out2 = []
          out2 << options[:left_image]
          context.safe_join(out2)
        end
        out << context.content_tag(:span, data: {role: 'notification-body'}, class: 'notification-body') do
          options[:body_text]
        end
        out << context.content_tag(:div, data: {role: 'notification-target-image'},
                                   class: 'notification-target-image-container') do
          out2 = []
          out2 << options[:right_image]
          context.safe_join(out2)
        end
        context.safe_join(out)
      end
    end

    def args
      [self, viewer]
    end

    def i18n_key
      :text_html
    end

    def i18n_scope
      raise NotImplementedError
    end

    def i18n_params
      {}
    end

    # Returns an instance of the exhibit class appropriate to +notification+'s type.
    def self.factory(notification, *rest)
      types = notification.type.to_s.underscore.gsub(/_notification\z/, '').split('_')
      # Because the notification type is based off of the lagunitas notification type, user notifications
      # would sit at the top level (exhibits/notifications) without this.  Per Brian's suggestion, in the
      # future we may want to have a notification model decorate the lagunitas model and perform our
      # own custom notification typing in brooklyn.
      types.unshift("user") if types.count == 1
      subtype = types.shift.camelize
      exhibit_type = "#{types.join('_').camelize}Exhibit"
      Notifications.const_get(subtype).const_get(exhibit_type).new(notification, *rest)
    rescue NameError
      logger.warn "No exhibit class for #{notification.type}"
      nil
    end
  end
end

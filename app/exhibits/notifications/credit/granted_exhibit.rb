module Notifications
  module Credit
    class GrantedExhibit < BaseExhibit
      if feature_enabled?('notifications.layout.v2')
        include Exhibitionist::RenderedWithCustom

        custom_render do |exhibit, viewer|
          if exhibit.offer.descriptor?
            descriptor = exhibit.offer.descriptor
            scope = [:credit, :granted, :descriptor]
          else
            descriptor = nil
            scope = [:credit, :granted, :no_descriptor]
          end
          exhibit.render_notification(
            target: settings_credits_url,
            body_text: nt(:self_html, scope: scope,
              descriptor: descriptor,
              amount: smart_number_to_currency(exhibit.credit.amount),
              expiration: date(exhibit.credit.expires_at)),
            left_image: copious_logo_image_tag,
            right_image: copious_credit_image_tag
          )
        end
      else
        include Exhibitionist::RenderedWithPartial
        set_partial '/notifications/credit_granted'
      end
    end
  end
end

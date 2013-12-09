module Admin
  module Facebook
    module AnnouncementsHelper

      def admin_facebook_announcement_buttons(options = {})
        out = []
        out << bootstrap_button('Yes, send the announcement', admin_facebook_announcements_path, method: :post,
                                remote: true, condition: :primary, data: {action: 'announce'})
        out << bootstrap_modal_close_admin(options.merge(close_button_text: 'No, thanks for saving me from myself'))
        safe_join(out, ' ')
      end
    end
  end
end

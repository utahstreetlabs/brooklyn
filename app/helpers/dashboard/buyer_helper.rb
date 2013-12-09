require 'exhibitionist'

module Dashboard
  module Buyer
    # An exhibit for the listing row on the Items I've Bought page.
    class ListingExhibit < Exhibitionist::Exhibit
      include Exhibitionist::RenderedWithPartial
      set_partial '/dashboard/bought_listing.html'

      def locals
        {listing: self}
      end
    end

    # A base class for next steps on the Items I've Bought page.
    class BuyerOrderNextStepExhibit < OrderNextStepExhibit
      def self.i18n_scope
        'exhibits.dashboard.buyer'
      end
    end

    # An exhibit that renders the delivery confirmation modal.
    class DeliveryConfirmationElapsedExhibit < BuyerOrderNextStepExhibit
      def render
        update_button +
        modal_container do
          update_modal
        end
      end

      def update_button
        context.bootstrap_button(t('delivery_confirmation_elapsed.button'), '#', toggle_modal: modal_id)
      end

      def update_modal
        context.bootstrap_modal(modal_id, t('delivery_confirmation_elapsed.modal.title'), show_save: false,
                                show_close: false, show_footer: false,
                                data: {next_step: 'update-delivery', role: 'dash-order-modal'}) do
          modal_content_container do
            context.content_tag(:p) do
              t('delivery_confirmation_elapsed.modal.text')
            end +
            context.content_tag(:h3, class: 'inline-block-element margin-right-onehalf') do
              t('delivery_confirmation_elapsed.modal.tracking_number', number: self.tracking_number)
            end +
            tracking_button +
            context.content_tag(:div, :class => 'buttons') do
              delivered_button +
              not_delivered_button
            end
          end
        end
      end

      def tracking_button
        context.bootstrap_button(t('delivery_confirmation_elapsed.modal.button.track'), context.tracking_url(self),
                                 target: '_tracking', data: {action: 'track'})
      end

      def delivered_button
        context.bootstrap_button(t('delivery_confirmation_elapsed.modal.button.delivered'),
                                 context.dashboard_order_delivered_path(self), method: :post, remote: true,
                                 data: {action: 'confirm-delivery', link: 'multi-remote'}, class: 'margin-right')
      end

      def not_delivered_button
        context.bootstrap_button(t('delivery_confirmation_elapsed.modal.button.not_delivered'),
                                 context.dashboard_order_not_delivered_path(self), method: :post, remote: true,
                                 data: {action: 'report-non-delivery', link: 'multi-remote'})
      end

      def modal_id
        "update-delivery-#{self.id}"
      end
    end

    # An exhibit that renders the delivery confirmed modal.
    class DeliveryConfirmedExhibit < BuyerOrderNextStepExhibit
      def render
        context.bootstrap_modal(modal_id, t('delivery_confirmed.modal.title'), show_save: false) do
          modal_content_container do
            context.content_tag(:p) do
              t('delivery_confirmed.modal.text_html',
                review_remaining: context.count_of_days_in_words(review_remaining),
                help_link: context.mail_to(Brooklyn::Application.config.email.to.help))
            end
          end
        end
      end

      def modal_id
        "delivery-confirmed-#{self.id}"
      end
    end

    # An exhibit that renders the delivery not confirmed modal.
    class DeliveryNotConfirmedExhibit < BuyerOrderNextStepExhibit
      def render
        context.bootstrap_modal(modal_id, t('delivery_not_confirmed.modal.title'), show_save: false) do
          modal_content_container do
            context.content_tag(:p) do
              t('delivery_not_confirmed.modal.text_html',
                help_link: context.mail_to(Brooklyn::Application.config.email.to.help))
            end
          end
        end
      end

      def modal_id
        "delivery-not-confirmed-#{self.id}"
      end
    end
  end

  module BuyerHelper
    # required by Rails for autoloading
  end
end

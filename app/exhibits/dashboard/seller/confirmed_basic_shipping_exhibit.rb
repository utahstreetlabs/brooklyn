module Dashboard
  module Seller
    class ConfirmedBasicShippingExhibit < Dashboard::OrderNextStepExhibit
      def render
        button + modal_container { modal }
      end

      def button
        context.bootstrap_button(t('button.ship'), '#', toggle_modal: modal_id, class: 'button')
      end

      def modal
        context.bootstrap_modal(modal_id, t('modal.title'), show_save: false, show_close: false,
                                show_footer: false, data: {role: 'dash-order-modal'}) do
          modal_content_container do
            out = []
            context.content_tag(:p, t('modal.text_html'))
            out << context.bootstrap_form_for((shipment || build_shipment), url: context.order_ship_path(self.id),
                                              remote: true, html: {method: :post}) do |f|
              out2 = []
              out2 << context.hidden_field_tag(:source, 'dashboard')
              out2 << f.label(:carrier_name, t('modal.carrier.label'))
              out2 << context.carrier_selector
              out2 << f.text_field(:tracking_number, t('modal.tracking_number.label'), size: 22)
              out2 << f.submit(t('modal.button.submit'), data: {disable_with: t('modal.disable.submit_html')},
                               base_class: 'button primary clear large')
              context.safe_join(out2)
            end
            context.safe_join(out)
          end
        end
      end

      def modal_id
        "ship-order-#{self.id}"
      end

      def self.i18n_scope
        'exhibits.dashboard.seller.confirmed_basic_shipping'
      end
    end
  end
end

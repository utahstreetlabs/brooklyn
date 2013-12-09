module Listings
  module Orders
    module Seller
      class CompleteExhibit < Listings::Orders::SellerExhibit
        include Exhibitionist::RenderedWithCustom

        custom_render do |listing, viewer|
          out = []
          out << content_tag(:h2, t('.header_html'))
          if current_user.default_deposit_account?
            if current_user.default_deposit_to_paypal?
              out << content_tag(:h2, class: 'inline-block-element pull-left') do
                t('.deposit_funds.paypal.instructions_html', amount: number_to_currency(listing.proceeds))
              end
              out << link_to(t('.deposit_funds.paypal.button.release'), settle_orders_path, method: :post,
                             class: 'primary button large pull-right margin-top-quarter',
                             data: {:'disable-with' => t('.deposit_funds.paypal.disable.release_html')})
              out << content_tag(:p, t('.deposit_funds.paypal.sucks_html'), class: 'span12')
              out << link_to(t('.deposit_funds.paypal.button.add_bank_account'), settings_seller_accounts_path,
                             class: 'button large pull-right margin-top-quarter')
            else
              out << content_tag(:h2, class: 'inline-block-element pull-left') do
                t('.deposit_funds.bank_account.instructions_html', amount: number_to_currency(listing.proceeds))
              end
              out << link_to(t('.deposit_funds.bank_account.button'), settle_orders_path, method: :post,
                             class: 'primary button large pull-right margin-top-quarter',
                             data: {:'disable-with' => t('.deposit_funds.bank_account.disable_html')})
            end
          elsif current_user.balanced_merchant?
            out << content_tag(:h2, class: 'inline-block-element pull-left') do
              t('.connect_bank_account.instructions_html', amount: number_to_currency(listing.proceeds))
            end
            out << link_to(t('.connect_bank_account.button'), settings_seller_accounts_path,
                           class: 'primary button large pull-right margin-top-quarter')
          else
            out << content_tag(:h2, class: 'inline-block-element pull-left') do
               t('.create_merchant_account.instructions_html', amount: number_to_currency(listing.proceeds))
             end
             out << link_to(t('.create_merchant_account.button'), settings_seller_accounts_path,
                            class: 'primary button large pull-right margin-top-quarter')
          end
          safe_join(out)
        end
      end
    end
  end
end

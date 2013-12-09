module Listings::PurchaseHelper
  FLOW_STEPS = ['Sign in', 'Shipping', 'Purchase', 'Purchase Confirmation']

  def purchase_flow_step(step)
    @purchase_flow_step = step
  end

  def purchase_progress_bar
    content_tag :div, class: 'progress-bar-container' do
      content_tag :table, class: 'progress-bar' do
        content_tag :tr do
          out = raw('')
          FLOW_STEPS.each_with_index do |step, i|
            num = i+1
            td_class = num == @purchase_flow_step ? 'current' : nil
            out << content_tag(:td, class: td_class) do
              content_tag(:div, num, class: 'progress-number') +
              content_tag(:span, step, class: 'progress-text')
            end
          end
          out
        end
      end
    end
  end

  def link_to_cancel_purchase(listing, options = {})
    text = options[:text]
    css_class = options[:class] || ''
    text ||= ''
    css_class = css_class + "close cancel-purchase-button"
    link_to(text, listing_purchase_path(listing), class: css_class, title: t('.button.cancel'), rel: 'tooltip',
            data: {method: :delete, role: 'reserved-time-cancel'})
  end

  def purchase_order_reserved_time_ticker(order)
    content_tag(:div, nil, :'data-role' => "reserved-time-ticker", :'data-ticker-expiry' => order.expires_at,
      :class => 'reserved-time-container')
  end

  def purchase_order_details(listing, options = {}, &block)
    content_tag(:div, :class => 'order-details-window') do
      content_tag(:div, :class => 'order-details-product-wrapper') do
        content_tag(:h4, listing.title, :class => 'order-details-title normal-weight') +
        content_tag(:span, "Sold by #{listing.seller.name}", :class => 'seller-name') +
        listing_photo_tag(listing.photos.first, :large, :class => 'listing-photo')
      end +
      content_tag(:div, :class => 'right-pane') do
        content_tag(:div, id: 'buyer-price-details') do
          out = raw('')
          out << content_tag(:div, class: 'label margin-bottom') do
            out2 = ['Order Summary']
            out2 << link_to('Edit', shipping_listing_purchase_path(listing), :class => 'edit') if options[:edit_link]
            raw(out2.join(' '))
          end
          out << checkout_price_detail('Price', listing.price, 'display-price')
          out << checkout_price_detail('Shipping', listing.shipping, 'shipping-price')
          out << checkout_price_detail('Copious Fees', listing.buyer_fee, 'copious-price')
          out << content_tag(:div, :class => 'credits-applied-container') do
            credit_options = {}
            credit_options[:style] = 'display:none' unless listing.order.credit_applied?
            checkout_price_detail('Credits Applied', -listing.order.credit_amount, 'credit', credit_options)
          end
          if options[:remaining_credit]
            balance = current_user.credit_balance
            formatted = number_to_currency(balance.abs)
            formatted = balance >= 0 ? "#{formatted} Credits remaining" : "(#{formatted}) Credits overdrawn"
            out << content_tag(:div, formatted, class: 'remaining-credits')
          end
          out << content_tag(:div, :class => 'total-container') do
            checkout_price_detail('Total', listing.order.total_price, 'total-price')
          end
          out
        end +
        capture { yield }
      end
    end
  end
end

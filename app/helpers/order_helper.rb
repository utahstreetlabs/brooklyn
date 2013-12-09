module OrderHelper
  def order_privacy_hint
    qmark_tooltip(t('shared.orders.privacy.hint')).html_safe
  end

  def order_status(order)
    case order.status.to_sym
    when :confirmed then ['Purchase confirmed', 'Not shipped']
    when :shipped
      status = t('.shipped.status')
      substatus = if order.delivery_confirmation_elapsed?
        t('.shipped.substatus.delivery_confirmation_elapsed_html', tracking_number: order.tracking_number)
      else
        t('.shipped.substatus.delivery_confirmation_pending_html', tracking_number: order.tracking_number)
      end
      [status, substatus]
    when :delivered
      ['Delivered', order.review_period_ends_at < Time.now ? "Review period has ended" : "Review period ends in #{tx_review_period_left_in_words(order)}"]
    when :complete then [t('.complete.status'), t('.complete.substatus')]
    when :settled
      status = [t('.settled.status')]
      substatus = if order.listing.sold_by?(current_user)
        if order.seller_payment
          t(".settled.substatus.#{order.seller_payment.state}")
        else
          # we don't have enough information about payment state so assume it's pending
          t('.settled.substatus.pending')
        end
      else
        t('.settled.substatus')
      end
      [status, substatus]
    when :canceled
      ss = order.shipped_at.blank?? 'Did not ship' : 'Did not arrive'
      ['Canceled', "#{ss}, fully refunded"]
    when :return_pending then ['Issue reported', 'Return pending']
    when :return_shipped then ['Issue reported', "Return shipped ##{order.return_tracking_number}"]
    when :return_delivered then ['Issue reported', 'Return delivered, pending confirmation']
    when :return_complete then ['Issue reported', 'Return confirmed, fully refunded']
    else [nil, nil]
    end
  end

  def order_details_status(order)
    status, substatus = order_status(order)
    out = []
    out << status if status.present?
#    out << content_tag(:span, substatus) if substatus.present?
    out.join(' - ').html_safe
  end

  def order_rating(rating)
    if rating.flag?
      'Positive'
    elsif rating.flag.nil?
      'Neutral'
    else
      'Negative'
    end
  end

  def order_rating_comments(rating)
    rating.comments || 'none'
  end

  def tx_review_period_in_words(order)
    time_ago_in_words(Time.now - Order.review_period_duration)
  end

  def tx_review_period_left_in_words(order)
    time_ago_in_words(order.review_period_ends_at)
  end
end

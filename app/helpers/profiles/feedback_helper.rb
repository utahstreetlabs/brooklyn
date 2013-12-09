module Profiles
  module FeedbackHelper
    def feedback_summary(user, options = {})
      total_text = t('shared.feedback.summary.total', count: feedback_total_successful_transactions(user))
      percent_text = raw(t('shared.feedback.summary.percent',
        percent: content_tag(:strong, feedback_percent_successful_transactions(user))))
      text = safe_join [total_text, percent_text], (options[:without_break] ? ' ' : tag(:br))
      options.reverse_merge!(data: {role: :'feedback-summary'}, class: 'feedback-summary')
      content_tag(:div, options) do
        if logged_in?
          link_to(text, selling_public_profile_feedback_index_path(user))
        else
          text
        end
      end
    end

    def profile_feedback_tabs(user)
      tab_items = [
        ['Selling', selling_public_profile_feedback_index_path(user), {}, {unless_current: true}],
        ['Buying',  buying_public_profile_feedback_index_path(user),  {}, {unless_current: true}]
      ]
      bootstrap_tabs(tab_items, class: 'feedback-tabs')
    end

    def feedback_total_successful_transactions(user)
      OrderRating.count_transactions_for_user(user.id)
    end

    def feedback_percent_successful_transactions(user)
      number_to_percentage(OrderRating.percent_successful_transactions_for_user(user.id), precision: 0)
    end

    def feedback_outcome(feedback, viewer, type)
      case type
      when :selling then feedback_selling_outcome(feedback, viewer)
      when :buying then feedback_buying_outcome(feedback, viewer)
      end
    end

    def feedback_selling_outcome(feedback, viewer)
      out = []
      # there are no places where the system assigns neutral seller feedback
      if feedback.rated_positive?
        out << feedback_selling_success_outcome(feedback, viewer)
      elsif feedback.rated_negative?
        out << feedback_selling_failure_outcome(feedback, viewer)
      end
      out << feedback_selling_buyer_made_private(feedback, viewer)
      safe_join(out.compact, '')
    end

    def feedback_selling_success_outcome(feedback, viewer)
      if feedback.sold_by?(viewer)
        feedback_success_outcome(t('.selling.successful.seller.header'), t('.selling.successful.seller.description'))
      elsif feedback.bought_by?(viewer)
        feedback_success_outcome(t('.selling.successful.buyer.header'), t('.selling.successful.buyer.description'))
      else
        feedback_success_outcome(t('.selling.successful.other.header'), t('.selling.successful.other.description'))
      end
    end

    def feedback_selling_failure_outcome(feedback, viewer)
      if feedback.failed_due_to_non_shipment?
        if feedback.sold_by?(viewer)
          feedback_failure_outcome(t('.selling.cancelled.seller.header'),
            t('.selling.cancelled.seller.unshipped.description'))
        elsif feedback.bought_by?(viewer)
          feedback_failure_outcome(t('.selling.cancelled.buyer.header'),
            t('.selling.cancelled.buyer.unshipped.description'))
        else
          feedback_failure_outcome(t('.selling.cancelled.other.header'),
            t('.selling.cancelled.other.unshipped.description'))
        end
      end
    end

    def feedback_selling_buyer_made_private(feedback, viewer)
      feedback_buyer_made_private(feedback, viewer, t('.selling.buyer_made_private'))
    end

    def feedback_buying_outcome(feedback, viewer)
      out = []
      # there are no places where the system assigns negative buyer feedback
      if feedback.rated_positive?
        out << feedback_buying_success_outcome(feedback, viewer)
      elsif feedback.rated_neutral?
        out << feedback_buying_failure_outcome(feedback, viewer)
      end
      out << feedback_buying_buyer_made_private(feedback, viewer)
      safe_join(out.compact, '')
    end

    def feedback_buying_success_outcome(feedback, viewer)
      if feedback.sold_by?(viewer)
        feedback_success_outcome(t('.buying.successful.seller.header'), t('.buying.successful.seller.description'))
      elsif feedback.bought_by?(viewer)
        feedback_success_outcome(t('.buying.successful.buyer.header'), t('.buying.successful.buyer.description'))
      else
        feedback_success_outcome(t('.buying.successful.other.header'), t('.buying.successful.other.description'))
      end
    end

    def feedback_buying_failure_outcome(feedback, viewer)
      if feedback.failed_due_to_non_shipment?
        if feedback.sold_by?(viewer)
          feedback_failure_outcome(t('.buying.cancelled.seller.header'),
            t('.buying.cancelled.seller.unshipped.description'))
        elsif feedback.bought_by?(viewer)
          feedback_failure_outcome(t('.buying.cancelled.buyer.header'),
            t('.buying.cancelled.buyer.unshipped.description'))
        else
          feedback_failure_outcome(t('.buying.cancelled.other.header'),
            t('.buying.cancelled.other.unshipped.description'))
        end
      end
    end

    def feedback_buying_buyer_made_private(feedback, viewer)
      feedback_buyer_made_private(feedback, viewer, t('.buying.buyer_made_private'))
    end

    def feedback_success_outcome(header, description)
      out = []
      out << content_tag(:span, header, class: 'feedback-outcome-successful')
      out << content_tag(:span, description, class: 'meta')
      safe_join(out, '')
    end

    def feedback_failure_outcome(header, description)
      out = []
      out << content_tag(:span, header, class: 'feedback-outcome-fail')
      out << content_tag(:span, description, class: 'meta')
      safe_join(out, '')
    end

    def feedback_buyer_made_private(feedback, viewer, text)
      unless feedback.visible_to?(viewer)
        out = []
        out << tag(:br)
        out << content_tag(:span, text, class: 'meta')
        safe_join(out, '')
      end
    end

    def feedback_partner(feedback, viewer, type)
      if feedback.visible_to?(viewer)
        case type
        when :selling
          # because there's no way for a buyer to retroactively make a canceled order private, we hide the buyer
          # when a third party is looking at a seller's negative feedback
          unless feedback.rated_negative? && ! (feedback.sold_by?(viewer) || feedback.bought_by?(viewer))
            link_to_user_profile feedback.buyer, url: buying_public_profile_feedback_index_path(feedback.buyer)
          end
        when :buying
          link_to_user_profile feedback.seller, url: selling_public_profile_feedback_index_path(feedback.seller)
        end
      end
    end

    def feedback_purchase_date(feedback, viewer)
      date(feedback.purchased_at) if feedback.purchased_at.present?
    end

    def feedback_listing(feedback, viewer)
      link_to_listing feedback.listing if feedback.visible_to?(viewer)
    end

    def feedback_price(feedback, viewer)
      number_to_currency(feedback.price) if feedback.visible_to?(viewer)
    end

    def feedback_photo(feedback, viewer)
      if feedback.visible_to?(viewer)
        link_to listing_photo_tag(feedback.photo, :small), listing_path(feedback.listing),
          class: 'thumbnail text-adjacent'
      end
    end

    def feedback_zero_message(profile_user, viewer, type)
      case type
      when :selling
        if profile_user == viewer
          raw(t('.selling.zero.seller', listing_link: link_to(t('.selling.zero.listing_link'), new_listing_path)))
        else
          t('.selling.zero.other', firstname: profile_user.firstname)
        end
      when :buying
        if profile_user == viewer
          raw(t('.buying.zero.buyer', feed_link: link_to(t('.buying.zero.feed_link'), root_path)))
        else
          t('.buying.zero.other', firstname: profile_user.firstname)
        end
      end
    end

    def link_to_feedback(text, rating, user = nil)
      user ||= rating.user
      url = rating.is_a?(BuyerRating) ? buying_public_profile_feedback_index_path(user) :
        selling_public_profile_feedback_index_path(user)
      link_to(text, url)
    end
  end
end

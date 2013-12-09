require 'brooklyn/sprayer'
require 'ladon'

module OrderRatings
  class AfterCreationJob < Ladon::Job
    include Brooklyn::Sprayer

    @queue = :orders

    class << self
      def work(id)
        with_error_handling("After creation of order rating #{id}") do
          rating = OrderRating.find(id)
          inject_feedback_notification(rating)
        end
      end

      def inject_feedback_notification(rating)
        if rating.positive?
          inject_feedback_increased_notification(rating)
        elsif rating.negative?
          inject_feedback_decreased_notification(rating)
        end
      end

      def inject_feedback_increased_notification(rating)
        inject_notification(:FeedbackIncreased, rating.user_id, rating_id: rating.id)
      end

      def inject_feedback_decreased_notification(rating)
        inject_notification(:FeedbackDecreased, rating.user_id, rating_id: rating.id)
      end
    end
  end
end

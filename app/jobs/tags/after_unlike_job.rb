require 'brooklyn/sprayer'
require 'ladon'

module Tags
  class AfterUnlikeJob < Ladon::Job
    include Brooklyn::Sprayer

    @queue = :tags

    class << self
      def work(tag_id, unliker_id, options = {})
        with_error_handling("After unlike of tag #{tag_id}") do
          tag = Tag.find(tag_id)
          unliker = User.find(unliker_id)
          like = Pyramid::User::Likes.get(unliker_id, :tag, tag_id)
          # note that updating mixpanel for every like counts re-likes, but this is what we were doing before when
          # we updated mixpanel at the controller level
          update_mixpanel
          # In the event of an error, we get back nil from pyramid; we're going to just
          # be silent and not inject notifications, etc. in this case.
          return if like.present?
          # inject notifications, etc, per comment above
        end
      end

      def update_mixpanel
        track_usage(:unlike_listing)
      end
    end
  end
end

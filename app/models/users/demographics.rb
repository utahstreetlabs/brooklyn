require 'active_support/concern'

module Users
  # Provides access to various attributes we access frequently but don't want
  # in the main user model. We fetch them periodically from services or more
  # complex queries and cache them in the user stash
  module Demographics
    extend ActiveSupport::Concern
    include Ladon::ErrorHandling
    include Users::KeyValueStash
    include Stats::TutorialTracking

    def gender
      profile_value_from_stash(:gender)
    end

    def stash_gender(value)
      stash_value(:gender, value.to_sym)
    end

    def birthday
      v = profile_value_from_stash(:birthday)
      v.is_a?(String) && v.present? ? Date.parse(v) : v
    end

    # thanks, http://stackoverflow.com/questions/819263/get-persons-age-in-ruby
    def age
      bday = birthday
      if bday.present?
        a = Date.today.year - bday.year
        a -= 1 if Date.today < bday + a.years # for days before birthday
      end
    end

    def lister?
      boolean?(user_value_from_stash(:lister?))
    end

    def buyer?
      boolean?(user_value_from_stash(:buyer?))
    end

    def seller?
      boolean?(user_value_from_stash(:seller?))
    end

    def lover?
      likes_count > 0
    end

    def mark_lister!
      stash[:lister?] = true
    end

    def mark_buyer!
      stash[:buyer?] = true
    end

    def mark_seller!
      stash[:seller?] = true
    end

    def mark_inviter!
      if not inviter?
        track_tutorial_progress(:invite)
        update_attribute(:inviter, true)
      end
    end

    def mark_commenter!
      if not commenter?
        track_tutorial_progress(:comment)
        update_attribute(:commenter, true)
      end
    end

    private

    def stash_value(name, value)
      stash[name.to_sym] = value.to_sym
    end

    def from_stash(name, &block)
      stashed_value = (self.stash[name] ||= yield if persisted?)
      stashed_value.present?? stashed_value : nil
    end

    def fetch_from_profile(name)
      profile = person.for_network(:facebook)
      profile.send(name) if profile
    end

    def profile_value_from_stash(name)
      from_stash(name) { fetch_from_profile(name) }
    end

    def user_value_from_stash(name)
      from_stash(name) { self.send("query_#{name}") }
    end

    def boolean?(value)
      value == 'true' || value == true
    end

    def query_lister?
      visible_listings.any?
    end

    def query_buyer?
      bought_orders.where(status: :complete).any?
    end

    def query_seller?
      sold_orders.where(status: :complete).any?
    end
  end
end

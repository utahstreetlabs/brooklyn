require 'ladon'

module Users
  class AutofollowJob < Ladon::Job

    # use a different queue than :users so that we can make sure autofollows happen
    @queue = :autofollow

    def self.work(user_id)
      with_error_handling("Autofollow users", user_id: user_id) do
        user = User.find(user_id)
        autofollows = User.autofollow_list
        autofollows.each do |af|
          user.follow!(af, attrs: {suppress_followee_notifications: true, suppress_fb_follow: true}, follow_type: AutomaticFollow)
        end
      end
    end
  end
end

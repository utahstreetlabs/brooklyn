module Users
  class AfterFirstActivationJob < Ladon::Job
    include Brooklyn::Sprayer

    @queue = :users

    def self.work(id)
      with_error_handling("After user #{id}'s first listing activation") do
        user = User.find(id)
        update_mixpanel(user)
      end
    end

    def self.update_mixpanel(user)
      user.mixpanel_set!(first_listed_at: Time.zone.now)
    end
  end
end

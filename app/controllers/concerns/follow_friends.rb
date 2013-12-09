module Concerns
  module FollowFriends
    extend ActiveSupport::Concern
    included do
      helper_method :show_follow_friends?
    end

    def set_show_follow_friends
      session[:show_follow_friends] = true
    end

    def show_follow_friends?
      session.delete(:show_follow_friends) || params[:show_follow_friends]
    end
  end
end


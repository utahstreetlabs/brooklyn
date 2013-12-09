module Controllers
  module FeedPostable
    extend ActiveSupport::Concern

    module InstanceMethods
      def with_feed_post_error_handling(profile_id_or_person, network=nil)
        begin
          yield
        rescue MissingPermission
          profile = find_feed_post_profile(profile_id_or_person, network)
          message = I18n.t('controllers.profiles.error_missing_permission', link: auth_path(profile.network))
          render_jsend(fail: {message: message})
        rescue InvalidSession
          profile = find_feed_post_profile(profile_id_or_person, network)
          message = I18n.t('controllers.profiles.error_invalid_session', link: auth_path(profile.network))
          render_jsend(fail: {message: message})
        rescue ActionNotAllowed
          message = I18n.t('controllers.profiles.error_action_not_allowed')
          render_jsend(fail: {message: message})
        rescue RateLimited
          profile = find_feed_post_profile(profile_id_or_person, network)
          message = I18n.t('controllers.profiles.error_rate_limited_invite', network: profile.network.capitalize)
          render_jsend(fail: {message: message})
        rescue AccessTokenInvalid
          profile = find_feed_post_profile(profile_id_or_person, network)
          message = I18n.t('controllers.profiles.error_access_token_invalid', network: profile.network.capitalize, link: auth_path(profile.network))
          render_jsend(fail: {message: message})
        rescue Exception => e
          respond_error(e)
        end
      end

      def find_feed_post_profile(profile_id_or_person, network=nil)
        if profile_id_or_person.is_a?(Person)
          profile_id_or_person.for_network(network)
        else
          Profile.find(profile_id_or_person)
        end
      end
    end
  end
end

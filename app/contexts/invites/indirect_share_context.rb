require 'context_base'

module Invites
  class IndirectShareContext < ContextBase
    def self.share_dialog_url(network, user, view_context, options = {})
      scope = 'contexts.invites.indirect_share'
      name = URI.escape(translate(:name, view_context, name: user.firstname, scope: scope))
      desc = URI.escape(translate(:desc, view_context, name: user.firstname, scope: scope))
      url = url_escape(url_helpers.invite_url(user.untargeted_invite_code))
      picture = url_escape(absolute_url(user.profile_photo_url, root_url: url_helpers.root_url))
      redirect_url = url_escape(url_helpers.callbacks_shared_url)
      params = {text: name, link: url, picture: picture, redirect: redirect_url, desc: desc,
        ref: Network::Facebook::Ref.new(options[:fb_ref] || :inviteis2).to_ref,
        actions: [name: translate(:action_name, view_context, name: user.firstname), link: url].to_json}
      Network.external_share_dialog_url(network, params)
    end

    def self.translate(key, view_context, options)
      options[:scope] ||= "contexts.invites.indirect_share"
      options[:signup_offer_amount] ||= view_context.smart_number_to_currency(Credit.invitee_credit_amount)
      I18n.translate(key, options)
    end
  end
end

module FollowFriendsModalHelper
  def follow_friends_modal
    bootstrap_modal('follow-friends', t('onboarding_follow.modal.title'),
                    never_close: true, show_close: false, save_button_text: t('onboarding_follow.modal.save.label'),
                    data: {show: true, role: 'follow-friends-modal',
                           message: t('onboarding_follow.requests.message', follower: current_user.name)}) do
      out = []
      out << t('onboarding_follow.modal.description')
      out << content_tag(:div, data: {role: 'multi-friend-selector'}, id: 'signup_follow_container') do
        form_tag(complete_signup_buyer_friends_path, class: 'invite-friends-list', id: 'follow-friends-form',
                 data: {role: 'follow-friends-form'}, remote: true) do
          content_tag(:div, nil, data: {role: 'selectables'})
        end
      end

      out << content_tag(:div, class: 'select-all-container modal-checkbox-cta') do
        form_tag do
          out2 = []
          out2 << check_box_tag('select_all', 'select_all', false, id: 'select-all-friends')
          out2 << label_tag('select-all-friends', t('invite_modal.buttons.select_all'))
          safe_join(out2)
        end
      end
      safe_join(out)
    end
  end
end

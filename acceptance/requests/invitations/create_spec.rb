require './acceptance/spec_helper'

feature 'Create an invitation', js: true do
  before do
    login_as "starbuck@galactica.mil"
  end

  scenario 'using a custom modal' do
    pending "Invite modal has been removed.  Unpend if it comes back."
    open_invite_modal
    invite_modal_should_open_with_a_multi_friend_selector
  end

  def open_invite_modal
    open_modal(invite_modal_id)
  end

  def invite_modal_should_open_with_a_multi_friend_selector
    within_modal(invite_modal_id) do
      page.should have_selector('[data-role=multi-friend-selector]')
    end
  end

  def invite_modal_id
    'invite-friends'
  end
end

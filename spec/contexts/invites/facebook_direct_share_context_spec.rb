require 'spec_helper'

describe Invites::FacebookDirectShareContext do
  let(:photo) { 'http://static.tvtropes.org/pmwiki/pub/images/AdamaGlare2.jpg' }
  let(:viewer) { stub_user('William Adama', profile_photo_url: photo ) }
  let(:apollo) { stub_network_profile('lee-adama', :facebook) }
  let(:starbuck) { stub_network_profile('kara-thrace', :facebook) }
  let(:profiles) { [apollo, starbuck] }

  describe '#eligible_profiles' do
    it 'returns rendered html for profiles matching a query string' do
      name = 'a'
      renderer = mock('renderer')
      viewer.person.expects(:invite_suggestions).with(is_a(Integer), has_entries(name: name)).returns(profiles)
      profiles.each do |profile|
        renderer.expects(:render_to_string).with(has_entry(locals: {profile: profile})).returns('')
      end
      Invites::FacebookDirectShareContext.eligible_profiles(viewer, name: name, renderer: renderer)
    end
  end

  describe '#async_send_direct_shares' do
    it "enqueues invite jobs for each invitee" do
      invite = stub('invite', ids: profiles.map(&:id), message: "Get in here now!")
      invite.ids.each do |id|
        Facebook::DirectShareInviteJob.expects(:enqueue).with(viewer.person.id, id, message: invite.message, picture: photo)
      end
      Invites::FacebookDirectShareContext.async_send_direct_shares(viewer, invite)
    end
  end

  describe '#send_direct_share' do
    let(:inviter) { stub_user('Laura Roslin', profile_photo_url: photo ) }
    it "sends a direct share to a Facebook profile" do
      invitee_profile_id = apollo.id
      params = {message: 'Get in here now!'}
      inviter.person.expects(:invite!).with(invitee_profile_id, is_a(Proc), params: params)
      inviter.expects(:mark_inviter!)
      Invites::FacebookDirectShareContext.expects(:track_usage)
      Invites::FacebookDirectShareContext.send_direct_share(inviter.person, invitee_profile_id, params)
    end
  end
end

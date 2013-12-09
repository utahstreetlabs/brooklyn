require 'spec_helper'

describe Facebook::OpenGraphUser do
  class User
  end

  let(:user) { stub_user('Axl Rose') }
  let(:profile_url) { 'http://clickety/click' }

  subject { Facebook::OpenGraphUser }

  describe "#open_graph_post" do
    let(:profile) { stub('profile', id: 5555, uid: 6666) }

    it 'posts to the facebook timeline' do
      user.person.expects(:for_network).with(:facebook).returns(profile)
      profile.expects(:og_postable?).returns(true)
      profile.expects(:post_to_ticker)
      subject.open_graph_post(user, profile_url, :post)
    end

    it 'does not post if open graph is not allowed' do
      user.person.expects(:for_network).with(:facebook).returns(profile)
      profile.expects(:og_postable?).returns(false)
      profile.expects(:post_to_ticker).never
      subject.open_graph_post(user, profile_url, :post)
    end

    it 'does not post if there is no facebook profile' do
      user.person.expects(:for_network).with(:facebook).returns(nil)
      profile.expects(:og_postable?).never
      profile.expects(:post_to_ticker).never
      subject.open_graph_post(user, profile_url, :post)
    end

    it 'catches exceptions raised from og posts' do
      user.person.expects(:for_network).with(:facebook).returns(profile)
      profile.expects(:og_postable?).returns(true)
      profile.expects(:post_to_ticker).raises("Boom!")
      expect { subject.open_graph_post(user, profile_url, :post) }.not_to raise_error
    end
  end
end

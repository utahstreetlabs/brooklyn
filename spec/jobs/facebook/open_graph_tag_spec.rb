require 'spec_helper'

describe Facebook::OpenGraphTag do
  class Tag
  end

  class User
  end

  let(:user) { stub_user('Axl Rose') }
  let(:tag) { stub_tag 'Shaken', seller: user }
  let(:tag_url) { 'http://clickety/click' }

  subject { Facebook::OpenGraphTag }

  describe "#open_graph_post" do
    let(:profile) { stub('profile', id: 5555, uid: 6666) }
    let(:actor) { stub_user('Skunk Baxter') }
    let(:tag) { stub_tag 'Walrustache', approved?: true }
    let(:tag_url) { "/url/to/tag" }

    it 'posts to the facebook timeline' do
      actor.person.expects(:for_network).with(:facebook).returns(profile)
      profile.expects(:og_postable?).returns(true)
      subject.expects(:open_graph_props).returns({})
      profile.expects(:post_to_ticker)
      subject.open_graph_post(tag, tag_url, actor, :post)
    end

    it 'does not post if open graph is not allowed' do
      actor.person.expects(:for_network).with(:facebook).returns(profile)
      profile.expects(:og_postable?).returns(false)
      profile.expects(:post_to_ticker).never
      subject.open_graph_post(tag, tag_url, actor, :post)
    end

    it 'does not post if there is no facebook profile' do
      actor.person.expects(:for_network).with(:facebook).returns(nil)
      profile.expects(:og_postable?).never
      profile.expects(:post_to_ticker).never
      subject.open_graph_post(tag, tag_url, actor, :post)
    end

    it 'catches exceptions raised from og posts' do
      actor.person.expects(:for_network).with(:facebook).returns(profile)
      profile.expects(:og_postable?).returns(true)
      subject.expects(:open_graph_object_props).returns({})
      profile.expects(:post_to_ticker).raises("Boom!")
      expect { subject.open_graph_post(tag, tag_url, actor, :post) }.not_to raise_error
    end
  end
end

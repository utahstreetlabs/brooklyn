require 'spec_helper'

describe Tags::AfterLikeJob do
  let(:liker) { stub_user 'Ted Greene' }
  let(:seller) { stub_user 'Wes Montgomery' }
  let(:like) { stub('like') }
  let(:tag) { stub_tag 'Jazzy' }

  subject { Tags::AfterLikeJob }

  describe '#inject_like_story' do
    it 'injects tag liked story' do
      subject.expects(:inject_story).with(:tag_liked, liker.id, tag_id: tag.id)
      subject.inject_like_story(tag, liker)
    end
  end

  describe "#post_like_to_facebook" do
    it "posts a story to the timeline when allowed" do
      tag_url = subject.url_helpers.browse_for_sale_url(path_tags: tag.slug)
      liker.expects(:allow_autoshare?).with(:listing_liked, :facebook).returns(true)
      Facebook::OpenGraphTag.expects(:enqueue_at).with(is_a(Time), tag.id, tag_url, liker.id, :love)
      subject.post_like_to_facebook(tag, liker)
    end

    it "doesn't post a story to the ticker when disallowed" do
      liker.expects(:allow_autoshare?).with(:listing_liked, :facebook).returns(false)
      Facebook::OpenGraphTag.expects(:enqueue_at).never
      subject.post_like_to_facebook(tag, liker)
    end
  end
end

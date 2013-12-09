require 'spec_helper'

describe Listings::AfterCommentedJob do
  let(:seller) { stub_user 'Skunk Baxter' }
  let(:commenter) { stub_user 'Don Fagen' }
  let(:mentioned) { stub_user 'John Doe', id: 123 }
  let(:comment) { stub_comment commenter, 'Nice axe!' }
  let(:replier) { stub_user 'Jack Black' }
  let(:reply) { stub_comment replier, '\m/' }
  let(:reply_attrs) { {id: reply.id, text: reply.text, user_id: reply.user_id} }
  let(:listing) { stub_listing 'Flying V, awesome.', seller: seller }

  subject { Listings::AfterCommentedJob }

  describe "#process_mentions" do
    context "no mentions" do
      let(:options) { {keywords: {}} }
      it "does not send notifications" do
        subject.expects(:process_mentioned_copious).never
        subject.process_mentions(listing, commenter, comment, comment.text, options)
      end
    end

    context "one copious mention" do
      let(:keyword) { {id: 123, name: 'John Doe', type: 'cf'} }
      let(:options) { {keywords: {'John Doe' => keyword}} }
      it "sends copious user notification" do
        subject.expects(:process_mentioned_copious).with(listing, commenter, comment, keyword, comment.text)
        subject.process_mentions(listing, commenter, comment, comment.text, options)
      end
    end
  end

  describe "#process_mentioned_copious" do
    let(:keyword) { {id: 123, name: 'John Doe', type: 'cf'} }
    before { User.stubs(:find_registered_users).with(id: mentioned.id).returns([mentioned]) }

    it "sends copious notifications" do
      subject.expects(:inject_mentioned_notification_for_mentioned).with(listing, commenter, comment, mentioned, comment.text)
      subject.expects(:email_mentioned).with(listing, commenter, comment, mentioned)
      subject.process_mentioned_copious(listing, commenter, comment, keyword, comment.text)
    end
  end

  describe "#autoshare_commented" do
    it "enqueues the job" do
      listing_url = subject.url_helpers.listing_url(listing)
      Autoshare::ListingCommented.expects(:enqueue).with(listing.id, listing_url, commenter.id, comment.text)
      subject.autoshare_commented(listing, commenter, comment, comment.text)
    end
  end

  describe '#inject_commented_story' do
    it 'injects listing commented story' do
      subject.expects(:inject_listing_story).
        with(:listing_commented, commenter.id, listing, text: comment.text)
      subject.inject_commented_story(listing, commenter, comment, comment.text)
    end
  end

  describe "#email_commented" do
    it "enqueues the job" do
      seller.stubs(:allow_email?).with(:listing_comment).returns(true)
      subject.expects(:send_email).with(:commented, listing, commenter.id, comment.id)
      subject.email_commented(listing, commenter, comment)
    end

    it "doesn't enqueue the job if seller doesn't allow email" do
      seller.stubs(:allow_email?).with(:listing_comment).returns(false)
      subject.expects(:send_email).never
      subject.email_commented(listing, commenter, comment)
    end
  end

  describe "#email_replied" do
    it "enqueues the job" do
      commenter.stubs(:allow_email?).with(:listing_comment_reply).returns(true)
      subject.expects(:send_email).with(:replied, listing, commenter.id, comment.id, replier.id, reply.id)
      subject.email_replied(listing, commenter, comment, replier, reply_attrs)
    end

    it "doesn't enqueue the job if seller doesn't allow email" do
      commenter.stubs(:allow_email?).with(:listing_comment_reply).returns(false)
      subject.expects(:send_email).never
      subject.email_replied(listing, commenter, comment, replier, reply_attrs)
    end
  end

  describe "#email_mentioned" do
    it "enqueues the job" do
      mentioned.stubs(:allow_email?).with(:listing_mentioned).returns(true)
      subject.expects(:send_email).with(:mentioned, listing, commenter.id, comment.id, mentioned.id)
      subject.email_mentioned(listing, commenter, comment, mentioned)
    end

    it "doesn't enqueue the job if seller doesn't allow email" do
      mentioned.stubs(:allow_email?).with(:listing_mentioned).returns(false)
      subject.expects(:send_email).never
      subject.email_mentioned(listing, commenter, comment, mentioned)
    end
  end

  describe "#post_comment_to_facebook" do
    it "posts a story to the ticker when allowed" do
      listing_url = subject.url_helpers.listing_url(listing)
      commenter.expects(:allow_autoshare?).with(:listing_commented, :facebook).returns(true)
      Facebook::OpenGraphListing.expects(:enqueue_at).with(is_a(Time), listing.id, listing_url, listing.seller.id,
        :comment, is_a(Hash))
      subject.post_comment_to_facebook(listing, commenter, comment, comment.text)
    end

    it "doesn't post a story to the ticker when disallowed" do
      commenter.expects(:allow_autoshare?).with(:listing_commented, :facebook).returns(false)
      Facebook::OpenGraphListing.expects(:enqueue_at).never
      subject.post_comment_to_facebook(listing, commenter, comment, comment.text)
    end
  end

  describe '#update_mixpanel' do
    it 'increments mixpanel comments field' do
      commenter.expects(:mixpanel_increment!).with(:comments)
      subject.update_mixpanel(listing, commenter, source: 'feed')
    end
  end
end

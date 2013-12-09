require 'spec_helper'

describe Listings::Comments do
  subject { InternalListing.new }

  describe '#comment' do
    let(:commenter) { stub('commenter', id: 123) }
    let(:text) { 'meh' }
    let(:keywords) { ['foo', 'bar'] }
    let(:comment) { stub('comment', text: text, keywords: keywords, valid?: true) }

    it 'treats a keywords string as json' do
      Comment.expects(:create).with(subject, commenter, keywords: keywords).returns(nil)
      subject.comment(commenter, keywords: "[\"foo\",\"bar\"]")
    end

    it 'uses a keywords array as is' do
      Comment.expects(:create).with(subject, commenter, keywords: keywords).returns(nil)
      subject.comment(commenter, keywords: keywords)
    end

    it ' adds tags and notifies observers after creating a comment' do
      Comment.stubs(:create).with(subject, commenter, {text: text, keywords: keywords}).returns(comment)
      subject.expects(:add_tags_from_keywords).with(keywords)
      subject.expects(:notify_observers).with(:after_comment, commenter, comment, is_a(Hash))
      subject.comment(commenter, text: text, keywords: keywords)
    end

    it 'does not add tags or notify observers after failing to create an invalid comment' do
      comment.stubs(:valid?).returns(false)
      Comment.stubs(:create).with(subject, commenter, {text: text, keywords: keywords}).returns(comment)
      subject.expects(:add_tags_from_keywords).never
      subject.expects(:notify_observers).never
      subject.comment(commenter, text: text, keywords: keywords)
    end

    it 'does not add tags or notify observers after getting an error creating a comment' do
      Comment.stubs(:create).with(subject, commenter, {text: text, keywords: keywords}).returns(nil)
      subject.expects(:add_tags_from_keywords).never
      subject.expects(:notify_observers).never
      subject.comment(commenter, text: text, keywords: keywords)
    end
  end

  it "deletes a comment" do
    subject.id = 123
    comment = stub('comment', id: 'deadbeef', text: 'mmm. beef.')
    user = stub('user', id: 456)
    Anchor::Comment.expects(:find).with(subject.id, comment.id).returns(comment)
    comment.expects(:destroy)
    subject.delete_comment(comment.id, user).should be_nil
  end

  describe "#reply" do
    let(:replier) { stub_user('Mickey Rourke') }
    let(:attrs) { {text: 'blah blah blah'} }
    let(:comment) { stub('comment', id: 'deadbeef') }
    let(:reply) { stub('reply') }

    before { subject.stubs(:anchor_instance).returns(stub('anchor-listing')) }

    it "creates reply and fires callback" do
      reply.stubs(:valid?).returns(true)
      reply.stubs(:keywords).returns({})
      CommentReply.expects(:create).with(comment, replier, attrs).returns(reply)
      ListingObserver.instance.expects(:after_comment).with(subject, replier, reply,
        has_entries(type: :reply, keywords: {}))
      subject.reply(replier, comment, attrs).should == reply
    end

    it "fails to create reply and skips callback" do
      comment.expects(:create_reply).with(attrs).returns(nil)
      ListingObserver.instance.expects(:after_comment).never
      subject.reply(replier, comment, attrs).should be_nil
    end
  end
end

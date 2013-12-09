require 'spec_helper'

describe ListingMailer do
  let(:listing) { stub_listing('Nude Bronze Greek God', seller: stub_user('Wonder Woman', following?: false)) }

  it "builds a comment flagged message for admin" do
    comment = Comment.new(Anchor::Comment.new(id: 'deadbeef', user_id: 123))
    commenter = stub_user('Gross Porny Guy')
    flag = Anchor::CommentFlag.new(reason: 'porn', user_id: 456)
    flagger = stub_user('Upstanding Citizen')
    User.expects(:where).with(id: comment.user_id).returns([commenter])
    User.expects(:where).with(id: flag[:user_id]).returns([flagger])
    listing.expects(:find_comment).with(comment.id).returns(comment)
    expect { ListingMailer.comment_flagged_for_admin(listing, comment.id, flag) }.not_to raise_error
  end

  it 'raises a retryable exception when when flagged comment is not found' do
    comment_id = 'deadbeef'
    flag = Anchor::CommentFlag.new(reason: 'porn', user_id: 456)
    listing.stubs(:find_comment).with(comment_id).returns(nil)
    expect { ListingMailer.comment_flagged_for_admin(listing, comment_id, flag) }.
      to raise_error(SendModelMail::RetryableFailure)
  end

  it "builds an activated message for a follower of the seller" do
    follower = stub_user('Rilo Kiley')
    expect { ListingMailer.activated(listing, user_attrs(follower)) }.not_to raise_error
  end

  it "builds a welcome message for the seller" do
    expect { ListingMailer.seller_welcome(listing) }.not_to raise_error
  end

  it "builds a featured message for the seller" do
    expect { ListingMailer.featured(listing) }.not_to raise_error
  end

  it "builds a shared message for the seller" do
    sharer = stub_user('Veronica Mars')
    User.expects(:find).with(sharer.id).returns(sharer)
    network = :twitter
    expect { ListingMailer.shared(listing, sharer.id, network) }.not_to raise_error
  end

  it "builds a commented message for the seller" do
    commenter = stub_user('Glenn Danzig')
    User.stubs(:find).with(commenter.id).returns(commenter)
    comment = stub_comment(commenter, 'Mother, tell your children not to walk my way. Tell your children not to hear my words, what they mean, what they say. Mother!')
    listing.stubs(:find_comment).with(comment.id).returns(comment)
    Brooklyn::UsageTracker.expects(:async_track).
      with('email_comment send', commenter: commenter.slug, listing: listing.slug)
    expect { ListingMailer.commented(listing, commenter.id, comment.id) }.not_to raise_error
  end

  it 'raises a retryable exception when when comment is not found' do
    commenter = stub_user('Glenn Danzig')
    User.stubs(:find).with(commenter.id).returns(commenter)
    comment_id = 'deadbeef'
    listing.stubs(:find_comment).with(comment_id).returns(nil)
    expect { ListingMailer.commented(listing, commenter.id, comment_id) }.
      to raise_error(SendModelMail::RetryableFailure)
  end

  it "builds a replied message for the commenter" do
    commenter = stub_user('Mitt Romney', id: 123)
    User.stubs(:find).with(commenter.id).returns(commenter)
    comment = stub_comment(commenter, "I'm not going to wear rose-colored glasses when it comes to Russia, or Mr. Putin. And I'm certainly not going to say to him, I'll give you more flexibility after the election. After the election, he'll get more backbone.", id: 'comment')
    listing.stubs(:find_comment).with(comment.id).returns(comment)
    replier = stub_user('Barack Obama', id: 456)
    User.stubs(:find).with(replier.id).returns(replier)
    reply = stub_comment(replier, "You mention that we have fewer ships than we had in 1916. Well, governor we also have fewer horses and bayonets, because that nature of our military has changed.", id: 'reply')
    listing.stubs(:find_comment).with(reply.id).returns(reply)
    Brooklyn::UsageTracker.expects(:async_track).
      with('email_reply send', replier: replier.slug, commenter: commenter.slug, listing: listing.slug)
    expect { ListingMailer.replied(listing, commenter.id, comment.id, replier.id, reply.id) }.not_to raise_error
  end

  it 'raises a retryable exception when when original comment is not found' do
    commenter = stub_user('Mitt Romney', id: 123)
    User.stubs(:find).with(commenter.id).returns(commenter)
    comment_id = 'deadbeef'
    listing.stubs(:find_comment).with(comment_id).returns(nil)
    replier = stub_user('Barack Obama', id: 456)
    User.stubs(:find).with(replier.id).returns(replier)
    reply_id = 'cafebebe'
    expect { ListingMailer.replied(listing, commenter.id, comment_id, replier.id, reply_id) }.
      to raise_error(SendModelMail::RetryableFailure)
  end

  it 'raises a retryable exception when when reply is not found' do
    commenter = stub_user('Mitt Romney', id: 123)
    User.stubs(:find).with(commenter.id).returns(commenter)
    comment = stub_comment(commenter, "I'm not going to wear rose-colored glasses when it comes to Russia, or Mr. Putin. And I'm certainly not going to say to him, I'll give you more flexibility after the election. After the election, he'll get more backbone.", id: 'comment')
    listing.stubs(:find_comment).with(comment.id).returns(comment)
    replier = stub_user('Barack Obama', id: 456)
    User.stubs(:find).with(replier.id).returns(replier)
    reply_id = 'cafebebe'
    listing.stubs(:find_comment).with(reply_id).returns(nil)
    expect { ListingMailer.replied(listing, commenter.id, comment.id, replier.id, reply_id) }.
      to raise_error(SendModelMail::RetryableFailure)
  end

  it "builds a mentioned message for the mentioned" do
    commenter = stub_user('John Doe', id: 123)
    User.stubs(:find).with(commenter.id).returns(commenter)
    mentioned = stub_user('Jane Doe', id: 456)
    User.stubs(:find).with(mentioned.id).returns(mentioned)
    comment = stub_comment(commenter, 'Om nom nom @Jane Doe', id: 'comment')
    listing.stubs(:find_comment).with(comment.id).returns(comment)
    Brooklyn::UsageTracker.expects(:async_track).
      with('email_mention send', mentionee: mentioned.slug, mentioner: commenter.slug, listing: listing.slug)
    expect { ListingMailer.mentioned(listing, commenter.id, comment.id, mentioned.id) }.not_to raise_error
  end

  it 'raises a retryable exception when when comment with mention is not found' do
    commenter = stub_user('John Doe', id: 123)
    User.stubs(:find).with(commenter.id).returns(commenter)
    mentioned = stub_user('Jane Doe', id: 456)
    User.stubs(:find).with(mentioned.id).returns(mentioned)
    comment_id = 'deadbeef'
    listing.stubs(:find_comment).with(comment_id).returns(nil)
    expect { ListingMailer.mentioned(listing, commenter.id, comment_id, mentioned.id) }.
      to raise_error(SendModelMail::RetryableFailure)
  end

  context "builds a liked message for the seller" do
    let(:liker) { stub_mailer_user('Ani DiFranco', listings: [stub_listing('Nose Ring')]) }
    before do
      User.stubs(:find).with(liker.id).returns(liker)
      Brooklyn::UsageTracker.expects(:async_track).with('email_like send', liker: liker.slug, listing: listing.slug)
    end

    it "when the seller follows the liker" do
      listing.seller.stubs(:following?).with(liker).returns(true)
      expect { ListingMailer.liked(listing, liker.id) }.not_to raise_error
    end

    it "when the seller does not follow the liker" do
      listing.seller.stubs(:following?).with(liker).returns(false)
      expect { ListingMailer.liked(listing, liker.id) }.not_to raise_error
    end
  end

  def user_attrs(user)
    {id: user.id, name: user.name, slug: user.slug, email: user.email, firstname: user.firstname}
  end
end

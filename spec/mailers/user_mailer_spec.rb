require 'spec_helper'

describe UserMailer do
  let(:user) { stub_user('Jimmy Shaw') }
  let(:other_user) { stub_user('Emily Haines', following?: false) }
  let(:other_attrs) { {'name' => 'Emily Haines', 'firstname' => 'Emily', 'slug' => 'emily-haines'} }

  it "builds a reset password instructions message" do
    user.stubs(:reset_password_token).returns('deadbeef')
    expect { UserMailer.reset_password_instructions(user) }.not_to raise_error
  end

  it 'builds an invite message' do
    user.stubs(:untargeted_invite_code).returns('deadbeef')
    address = 'emily@example.com'
    message = 'Please to join'
    expect { UserMailer.invite(user, address, message) }.not_to raise_error
  end

  it "builds an invite accepted message" do
    expect { UserMailer.invite_accepted(user, other_attrs) }.not_to raise_error
  end

  it "builds a friend joined message" do
    User.expects(:find).with(1).returns(other_user)
    expect { UserMailer.friend_joined(user, 1) }.not_to raise_error
  end

  it "builds a new user welcome message" do
    user_attrs = {'name' => 'Emily Haines'}
    expect { UserMailer.welcome_1(user) }.not_to raise_error
  end

  it "builds a new user welcome series two message" do
    user_attrs = {'name' => 'Catfish Collins'}
    expect { UserMailer.welcome_2(user) }.not_to raise_error
  end

  it "builds a new user welcome series three message" do
    user_attrs = {'name' => 'Bootsy Collins'}
    expect { UserMailer.welcome_3(user) }.not_to raise_error
  end

  it "builds a new user welcome series four message" do
    user_attrs = {'name' => 'Bootsy Collins'}
    expect { UserMailer.welcome_4(user) }.not_to raise_error
  end

  it "builds a new user welcome series five message" do
    user_attrs = {'name' => 'Bootsy Collins'}
    expect { UserMailer.welcome_5(user) }.not_to raise_error
  end

  it "builds a draft reminder message for an incomplete listing" do
    listing = stub_listing('Beer Shark Mice', incomplete?: true, inactive?: false)
    expect { UserMailer.draft_listing_reminder(user, listing) }.not_to raise_error
  end

  it "builds a draft reminder message for an inactive listing" do
    listing = stub_listing('Upright Citizens Brigade', incomplete?: false, inactive?: true)
    expect { UserMailer.draft_listing_reminder(user, listing) }.not_to raise_error
  end

  it "builds an invitee has made a purchase message" do
    expect { UserMailer.invitee_purchase_credit(user, other_attrs) }.not_to raise_error
  end

  describe "#connection_digest" do
    it "should display the top 10 items in the user's feed" do
      tfl = (0..9).map { |n| stub_listing("listing #{n}") }.each_with_object({}) { |l, m| m[l] = Set.new([42]) }
      user.stubs(:top_feed_listings).with(limit: 10).returns(tfl)
      user.stubs(:follow_suggestions).returns((0..3).map do |n|
        stub_user("Bobby #{n}", recent_listing_ids: [], recent_listed_listing_ids: [])
      end)
      user.stubs(:following_follows_for).returns([])
      user.stubs(:closest_friends_among).returns([])

      UserMailer.connection_digest(user, user.top_feed_listings(limit: 10)).deliver
      (0..9).each do |n|
        ActionMailer::Base.deliveries.first.encoded.should have_content("listing #{n}")
      end
      (0..3).each do |n|
        ActionMailer::Base.deliveries.first.encoded.should have_content("Bobby #{n}")
      end
    end
  end
end

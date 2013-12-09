require 'spec_helper'

describe Facebook::NotificationLike do
  subject { Facebook::NotificationLike }
  let(:actor) { FactoryGirl.create(:registered_user, name: 'Wayne Shorter') }
  let(:actor_profile) { FactoryGirl.create(:network_profile, name: "Wayne Shorter", id: 5554, uid: 8887, user_id: 9876) }
  let(:seller) { FactoryGirl.create(:registered_user, name: 'Herbie Hancock') }
  let(:commenter) { FactoryGirl.create(:registered_user, name: 'Ron Carter') }
  let(:liker) { FactoryGirl.create(:registered_user, name: 'Tony Williams') }
  let(:saver) { FactoryGirl.create(:registered_user, name: 'Miles Davis') }
  let(:listing) { FactoryGirl.create(:active_listing, seller: seller, id: 22) }

  describe '#perform' do
    let(:listing_id) { 1 }
    let(:liker_id) { 2 }
    let(:like) { stub('like', user: actor) }

    before do
      Listing.expects(:find).with(listing_id).returns(listing)
      User.expects(:find).with(liker_id).returns(actor)
      subject.expects(:notification_post).with(listing, actor)
    end

    it 'posts the notification successfully' do
      subject.perform(listing_id, liker_id)
    end
  end

  describe 'notification_post' do
    let(:comment_profile) { FactoryGirl.create(:network_profile, name: "Ron Carter", id: 5555, uid: 8888) }
    let(:liker_profile) { FactoryGirl.create(:network_profile, name: "Tony Williams", id: 5556, uid: 8889) }
    let(:seller_profile) { FactoryGirl.create(:network_profile, name: "Herbie Hancock", id: 5557, uid: 8890) }
    let(:saver_profile) { FactoryGirl.create(:network_profile, name: "Miles Davis", id: 5558, uid: 8891) }

    before do
      Network::Facebook.stubs(:notification_batch_size).returns(2)
      actor.person.expects(:for_network).with(:facebook).returns(actor_profile)
      subject.expects(:commenters).with(listing, actor).returns([commenter])
      subject.expects(:likers).with(listing).returns([commenter, liker])
      listing.expects(:savers).returns([commenter, saver])
      Profile.expects(:find_for_people_and_network).with(is_a(Array), :facebook).twice.
        returns([comment_profile, liker_profile]).returns([seller_profile, saver_profile])
      actor_profile.expects(:follows_in).twice.returns([comment_profile, liker_profile]).
        returns([seller_profile, saver_profile])
      [comment_profile, liker_profile, seller_profile, saver_profile].each do |p|
        Facebook::NotificationLikePost.expects(:enqueue).with(listing.id, p.id, actor_profile.id).once
      end
    end

    it 'posts the notification, ignoring duplicates' do
      subject.notification_post(listing, actor)
    end
  end
end

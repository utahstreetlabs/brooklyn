require 'spec_helper'

describe Facebook::NotificationBase do
  subject { Facebook::NotificationBase }

  let(:listing) { FactoryGirl.create(:active_listing, seller: seller, id: 22) }
  let(:actor) { FactoryGirl.create(:registered_user, name: "Wayne Shorter") }
  let(:actor_profile) { FactoryGirl.create(:network_profile, name: "Wayne Shorter",
    id: 5554, uid: 8887, person_id: actor.person.id) }
  let(:seller) { FactoryGirl.create(:registered_user, name: 'Herbie Hancock') }

  context 'when returning Facebook friend profiles' do
    let(:user_friend) { FactoryGirl.create(:registered_user, name: 'Miles Davis') }
    let(:user_not_friend) { FactoryGirl.create(:registered_user, name: 'Thundarr the Barbarian') }

    describe 'commenters' do
      let(:summary) { { listing.id =>
          stub('comment_summary', commenter_ids: [user_friend.id, user_not_friend.id]) } }

      it "returns commenter users" do
        Listing.expects(:comment_summaries).with([listing.id], actor).returns(summary)
        User.expects(:where).with(id: [user_friend.id, user_not_friend.id]).
          returns([user_friend, user_not_friend])
        subject.commenters(listing, actor).should == [user_friend, user_not_friend]
      end
    end

    describe 'likers' do
      let(:summary) { stub('likes_summary', liker_ids: [user_friend.id, user_not_friend.id]) }

      it "returns liker users" do
        listing.expects(:likes_summary).returns(summary)
        User.expects(:where).with(id: [user_friend.id, user_not_friend.id]).
          returns([user_friend, user_not_friend])
        subject.likers(listing).should == [user_friend, user_not_friend]
      end
    end
  end
end

require 'spec_helper'

describe Facebook::NotificationCommentPost do
  subject { Facebook::NotificationCommentPost }
  let!(:actor) { FactoryGirl.create(:registered_user, name: 'Wayne Shorter') }
  let!(:actor_profile) { FactoryGirl.create(:network_profile, name: "Wayne Shorter", id: 5554, uid: 8887, user_id: 9876) }
  let(:seller) { FactoryGirl.create(:registered_user, name: 'Herbie Hancock') }
  let(:commenter) { FactoryGirl.create(:registered_user, name: 'Ron Carter') }
  let(:commenter_profile) { FactoryGirl.create(:network_profile, name: 'Ron Carter', id: 5555, uid: 8888, user_id: 9877) }
  let(:listing) { FactoryGirl.create(:active_listing, seller: seller, id: 22) }

  describe '#perform' do
    before do
      Listing.expects(:find).with(listing.id).returns(listing)
      Rubicon::FacebookProfile.expects(:find).
        with([actor_profile.id, commenter_profile.id]).returns([actor_profile, commenter_profile])
      subject.expects(:notification_post).with(listing, actor_profile, commenter_profile)
    end

    it 'posts the notification successfully' do
      subject.perform(listing.id, 5554, commenter_profile.id)
    end
  end

  describe 'notification_post' do
    let(:ref) { Network::Facebook.notification_comment_group }
    let(:href) { '/foo/bar' }
    let(:template) { I18n.t('networks.facebook.notification.comment.template', user_id: commenter_profile.uid,
                            listing_title: listing.title) }

    it 'posts the notification' do
      subject.expects(:listing_path).with(listing).returns(href)
      actor_profile.expects(:post_notification).with({ template: template, href: href, ref: ref })
      subject.notification_post(listing, actor_profile, commenter_profile)
    end
  end
end

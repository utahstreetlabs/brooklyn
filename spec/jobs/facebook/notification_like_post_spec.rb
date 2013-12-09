require 'spec_helper'

describe Facebook::NotificationLikePost do
  subject { Facebook::NotificationLikePost }
  let(:actor) { FactoryGirl.create(:registered_user, name: 'Wayne Shorter') }
  let(:actor_profile) { FactoryGirl.create(:network_profile, name: "Wayne Shorter", id: 5554, uid: 8887, user_id: 9876) }
  let(:seller) { FactoryGirl.create(:registered_user, name: 'Herbie Hancock') }
  let(:liker) { FactoryGirl.create(:registered_user, name: 'Ron Carter') }
  let(:liker_profile) { FactoryGirl.create(:network_profile, name: 'Ron Carter') }
  let(:listing) { FactoryGirl.create(:active_listing, seller: seller, id: 22) }

  describe '#perform' do
    before do
      Listing.expects(:find).with(listing.id).returns(listing)
      Rubicon::FacebookProfile.expects(:find).
        with([actor_profile.id, liker_profile.id]).returns([actor_profile, liker_profile])
      subject.expects(:notification_post).with(listing, actor_profile, liker_profile)
    end

    it 'posts the notification successfully' do
      subject.perform(listing.id, 5554, liker_profile.id)
    end
  end

  describe 'notification_post' do
    let(:ref) { Network::Facebook.notification_like_group }
    let(:href) { '/foo/bar' }
    let(:template) { I18n.t('networks.facebook.notification.love.template', user_id: liker_profile.uid,
                            listing_title: listing.title) }

    it 'posts the notification' do
      subject.expects(:listing_path).with(listing).returns(href)
      actor_profile.expects(:post_notification).with({ template: template, href: href, ref: ref })
      subject.notification_post(listing, actor_profile, liker_profile)
    end
  end
end

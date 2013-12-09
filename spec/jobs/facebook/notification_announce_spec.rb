require 'spec_helper'

describe Facebook::NotificationAnnounce do
  subject { Facebook::NotificationAnnounce }

  describe 'notification_post' do
    let(:user1) { FactoryGirl.create(:registered_user, name: 'Ron Carter') }
    let(:user2) { FactoryGirl.create(:registered_user, name: 'Tony Williams') }
    let(:user3) { FactoryGirl.create(:registered_user, name: 'Herbie Hancock') }
    let(:profile1) { FactoryGirl.create(:network_profile, name: "Ron Carter", id: 1, person_id: user1.person_id) }
    let(:profile2) { FactoryGirl.create(:network_profile, name: "Tony Williams", id: 2, person_id: user2.person_id) }
    let(:profile3) { FactoryGirl.create(:network_profile, name: "Herbie Hancock", id: 3, person_id: user3.person_id) }

    it 'posts the notification to the profiles' do
      expect { |b| User.find_registered_person_ids_in_batches(batch_size: 25, &b) }.
        to yield_successive_args([user1.person_id, user2.person_id, user3.person_id])
      Profile.expects(:find_for_people_and_network).returns([profile1, profile2, profile3])
      [profile1, profile2, profile3].each do |p|
        p.expects(:connected?).returns(true)
        Facebook::NotificationAnnouncePost.expects(:enqueue).with(p.id).once
      end
      subject.notification_post
    end
  end
end

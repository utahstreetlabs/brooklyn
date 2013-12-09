require 'spec_helper'

class TestFacebookException < Exception; end

describe FillLocation do
  subject { FillLocation }
  let(:location) { 'everywhere' }
  let(:user) { stub_user('mr. location', location: location) }
  let(:fb_location) { stub('profile location', name: 'somewhere else') }
  let(:profile) { stub("mr. location's profile", facebook_location: fb_location) }
  before do
    User.stubs(:find).with(user.id).returns(user)
    user.person.stubs(:for_network).with(:facebook).returns(profile)
  end

  it 'should not overwrite an existing location' do
    user.expects(:update_attribute).never
    subject.perform(user.id)
  end

  context 'when location is nil' do
    let(:location) { nil }

    it 'should update the location from facebook' do
      user.expects(:update_attribute).with(:location, fb_location.name)
      subject.perform(user.id)
    end

    context 'when fb location is nil' do
      let(:fb_location) { nil }

      it 'should update the location from facebook' do
        user.expects(:update_attribute).never
        subject.perform(user.id)
      end
    end
  end
end

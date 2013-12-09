require "spec_helper"

describe PublishSignup do
  let(:person) { stub('person') }
  let(:user) { stub('user', id: 1, firstname: 'test', person: person, profile_photo_url: 'http://zombo.com') }
  let(:profile) { stub ('profile') }

  it "should publish a signup message to an external network" do
    User.expects(:find).with(user.id).returns(user)
    person.expects(:network_profiles).returns({:facebook => profile})
    profile.expects(:feed_postable?).returns(true)
    profile.expects(:post_to_feed).with(has_entries name: kind_of(String), link: Brooklyn::Application.routes.url_helpers.signup_url)
    expect { PublishSignup.perform(user.id) }.not_to raise_error
  end
end

require 'spec_helper'

describe PersonHelper do
  let(:fb_profile) do
    stub('facebook_profile', typed_photo_url: 'http://photo', profile_url: 'http://profile', name: 'mr jones',
      network: :facebook)
  end
  let(:user) { stub_user(fb_profile.name) }
  let(:person) do
    person = stub('person', user: nil, registered?: false)
    person.stubs(:for_network).with(:facebook).returns(fb_profile)
    person
  end

  context "when creating an avatar" do
    context "for a person with no user account" do
      it "returns a facebook avatar" do
        person_avatar_small(person).should == link_to_profile_avatar(fb_profile)
      end
    end

    context "for a person with a user account" do
      before { person.stubs(:user).returns(user) }

      context "who is not registered" do
        it "returns a facebook avatar" do
          person_avatar_small(person).should == link_to_profile_avatar(fb_profile)
        end
      end

      context "who is registered" do
        before { person.stubs(:registered?).returns(true) }

        it "returns a user avatar" do
          person_avatar_small(person).should == user_avatar_xsmall(user)
        end
      end
    end
  end

  context "when creating a profile link" do
    context "for a person with no user account" do
      it "returns a facebook profile link" do
        link_to_person_profile(person).should == link_to_network_profile(fb_profile)
      end
    end

    context "for a person with a user account" do
      before { person.stubs(:user).returns(user) }

      context "who is not registered" do
        it "returns a facebook profile link" do
          link_to_person_profile(person).should == link_to_network_profile(fb_profile)
        end
      end

      context "who is registered" do
        before { person.stubs(:registered?).returns(true) }

        it "returns a usl public profile link" do
          link_to_person_profile(person).should == link_to_user_profile(user)
        end
      end
    end
  end

  def logged_in?
    true
  end
end

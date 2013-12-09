require 'spec_helper'

describe NetworkHelper do
  helper do
    def logged_in?
      true
    end
    def auth_path(network, options = {})
      "/auth/#{network}"
    end
  end

  let(:network) { :facebook }
  let(:profile) do
    Rubicon::FacebookProfile.new(network: network, token: 'deadbeef', uid: 12345, name: 'Warhorn Jonez',
      profile_url: '//profile')
  end
  let(:networks) { {network => profile} }

  describe "#social_networks" do
    context "for an anonymous user" do
      before { act_as_anonymous }

      it "shows a connected network" do
        profile.stubs(:connected?).returns(true)
        helper.social_networks(networks).should have_content(profile.name)
      end

      it "does not show an unconnected network link" do
        profile.stubs(:connected?).returns(false)
        helper.social_networks(networks).should_not have_content(profile.name)
      end
    end

    context "for a logged-in user" do
      before { act_as_rfb }

      it "shows a connected network" do
        profile.stubs(:connected?).returns(true)
        helper.social_networks(networks).should have_content(profile.name)
      end

      it "shows an unconnected network link" do
        profile.stubs(:connected?).returns(false)
        helper.social_networks(networks).should =~ /data-action="auth-#{network}"/
      end

      it "does not show an unconnected network link when not allowed" do
        profile.stubs(:connected?).returns(false)
        helper.social_networks(networks, unconnected: false).should_not =~ /data-role="auth-#{network}"/
      end
    end
  end

  describe "#link_to_network_profile" do
    context "when profile_url exists" do
      it "renders the url" do
        link = helper.link_to_network_profile(profile)
        link.should match /profile/
        link.should match /Warhorn Jonez/
      end
    end

    context "when profile_url doesn't exist" do
      let(:network_profile) do
        Rubicon::InstagramProfile.new(network: :instagram, token: 'deadbeef', uid: 12345, name: 'Crabby McCrabberton')
      end

      it "renders the username" do
        link = helper.link_to_network_profile(network_profile)
        link.should have_content("Crabby McCrabberton")
      end
    end
  end
end

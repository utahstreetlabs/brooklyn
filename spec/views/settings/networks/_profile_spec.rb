require "spec_helper"

describe "settings/networks/_profile" do
  let(:page) { Capybara::Node::Simple.new(rendered) }
  let(:network) { :facebook }
  let(:viewer_person) { stub_person 'superman-person', connected_networks: stub('networks', size: 2) }
  let(:identities) { stub('identities', count: 2) }
  let(:viewer) do
    stub_user('Superman', person: viewer_person, preferences: stub('preferences', never_autoshare: false),
      identities: identities)
  end

  before do
    controller.singleton_class.class_eval do
      protected
        def auth_path(network, options = {})
          "/auth/#{network}"
        end
        helper_method :auth_path

        def settings_has_autoshare_choices?(network)
          true
        end
        helper_method :settings_has_autoshare_choices?
    end
    act_as_rfb(viewer)
  end

  context "for a connected profile" do
    let(:profile) { stub_network_profile('Batman', network, connected?: true, can_disconnect?: true) }

    before { viewer.stubs(:allow_autoshare?).returns(true) }

    it "shows save button for network choices" do
      render_the_partial(network, profile)
      page.should have_button('Save Changes')
    end

    it "shows a disconnect button when the viewer has other connected networks" do
      render_the_partial(network, profile)
      page.should have_css('a.disconnect')
    end

    it "shows a connected message" do
      render_the_partial(network, profile)
      page.should have_content("You have connected #{profile.name} to your Copious account")
      page.should_not have_css('.connect-cta')
      page.should_not have_css('.connect-more-cta')
    end

    context 'when the viewer has no other connected networks' do
      let(:identities) { stub('identities', count: 1) }

      it "does not show a disconnect button when the viewer has no other connected networks" do
        render_the_partial(network, profile)
        page.should_not have_css('a.disconnect')
      end
    end
  end

  context "for an unconnected profile" do
    let(:profile) { nil }

    it "does not show save button for network choices" do
      render_the_partial(network, profile)
      page.should_not have_button('Save Changes')
    end

    it "does not show network choices" do
      render_the_partial(network, profile)
      page.should_not have_button('Save Changes')
    end

    it "shows a connect button" do
      render_the_partial(network, profile)
      page.should have_css('a.connect')
    end

    it "shows a connect more cta when asked to" do
      render_the_partial(network, profile, true)
      page.should have_css('.connect-more-cta')
      page.should_not have_css('.connect-cta')
    end

    it "shows a connect cta when asked to" do
      render_the_partial(network, profile, false)
      page.should have_css('.connect-cta')
      page.should_not have_css('.connect-more-cta')
    end
  end

  def render_the_partial(network, profile, connect_more = nil)
    locals = {network: network, profile: profile}
    locals[:connect_more] = connect_more if connect_more.present?
    render partial: 'settings/networks/profile', locals: locals
  end
end

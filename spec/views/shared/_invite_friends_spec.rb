require "spec_helper"

describe "shared/_invite_friends" do
  let(:page) { Capybara::Node::Simple.new(rendered) }
  let(:profile1) { stub_network_profile('profile', :facebook, name: 'Roman Polanksi') }
  let(:profile2) { stub_network_profile('profile', :facebook, name: 'Emmanuelle Seigner') }
  let(:suggestions) { [profile1] }

  before do
    act_as_rfb
    view.stubs(:inviter_profiles).returns([])
    view.stubs(:pileon_suggestion).returns(nil)
  end

  it "shows each suggestion" do
    render_the_partial
    suggestions.each do |profile|
      page.should have_suggestion(profile)
    end
  end

  context "when there are no suggestions" do
    let(:suggestions) { [] }

    it "does not show the section at all" do
      page.should_not have_content('INVITE YOUR FRIENDS')
    end
  end

  context "when there is a pile-on suggestion" do
    it "renders the pile-on text" do
      Person.any_instance.stubs(:for_network).returns(:facebook)
      view.stubs(:inviter_profiles).with(profile1).returns([profile2])
      view.stubs(:pileon_suggestion).returns(profile1)
      render_the_partial
      suggestions.each do |profile|
        page.should have_suggestion(profile)
      end
      page.should have_content("#{profile2.name} invited #{profile1.name}")
    end

    context "when there is more than one pile-on available" do
      let!(:profile3) { stub_network_profile('profile', :facebook, name: "Errol Morris") }
      let!(:suggestions) { [profile1, profile3] }

      it "renders at most one pile-on suggestion" do
        Person.any_instance.stubs(:for_network).returns(:facebook)
        view.stubs(:link_to_profile_avatar).returns('')
        view.stubs(:inviter_profiles).with(profile1).returns([profile2])
        view.stubs(:inviter_profiles).with(profile3).returns([profile2])
        view.stubs(:pileon_suggestion).returns(profile1)
        render_the_partial
        suggestions.each do |profile|
          page.should have_suggestion(profile)
        end
        page.should have_content("#{profile2.name} invited #{profile1.name}")
        page.should_not have_content("#{profile2.name} invited #{profile3.name}")
      end
    end
  end

  def render_the_partial
    render partial: 'shared/invite_friends', locals: {suggestions: suggestions}
  end

  def have_suggestion(profile)
    have_css("#invite-suggestion-#{profile.id}")
  end
end

require "spec_helper"

describe "connect/invites/index" do
  let(:page) { Capybara::Node::Simple.new(rendered) }
  let(:viewer) { stub_user 'Jason Molina', untargeted_invite_code: 'deadbeef' }

  before do
    act_as_rfb viewer
    view.stubs(:mp_view_event)
  end

  it "shows the viewer's untargeted invite link" do
    render
    page.should have_css("input[value='#{invite_url(viewer.untargeted_invite_code)}']")
  end

  it 'shows the invited modal when the user just sent some invites' do
    flash[:invited] = 3
    render
    page.should have_css('#invited-modal')
  end

  it 'does not show the invited modal when the user has not just sent some invites' do
    render
    page.should_not have_css('#invited-modal')
  end
end

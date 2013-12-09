require "spec_helper"

describe "admin/users/show" do
  let(:page) { Capybara::Node::Simple.new(rendered) }
  let(:user) { stub_user 'Katniss' }
  let(:viewer) { stub_user 'Peeta' }

  before do
    act_as_rfb(viewer)
    can(:update, user)
    can(:grant, Credit)
    can(:manage, UserSuggestion)
    can(:manage, UserAutofollow)
    can(:grant_superuser, user)
    can(:grant_admin, user)
    can(:deactivate, user)
    can(:reactivate, user)
    can(:destroy, user)
    assign(:user, user)
    user.stubs(:suggested_for_interests).returns([])
    user.stubs(:collections).returns([])
    viewer.stubs(:following?).with(user).returns(true)
  end

  it 'has a grant credit button' do
    render
    page.should have_grant_credit_button
  end

  it 'does not have a grant credit button for a user who does not have that capability' do
    cannot(:grant, Credit)
    render
    page.should_not have_grant_credit_button
  end

  it 'has a suggested button' do
    render
    page.should have_manage_suggestions_button
  end

  it 'does not have a suggested button for a user who does not have that capability' do
    cannot(:manage, UserSuggestion)
    render
    page.should_not have_manage_suggestions_button
  end

  it 'has an autofollow button' do
    render
    page.should have_autofollow_button
  end

  it 'does not have an autofollow button for a user who does not have that capability' do
    cannot(:manage, UserAutofollow)
    render
    page.should_not have_autofollow_button
  end

  it 'has a superuser button' do
    render
    page.should have_superuser_button
  end

  it 'does not have a superuser button for a user who does not have that capability' do
    cannot(:grant_superuser, user)
    render
    page.should_not have_superuser_button
  end

  it 'has a admin button' do
    render
    page.should have_admin_button
  end

  it 'does not have a admin button for a user who does not have that capability' do
    cannot(:grant_admin, user)
    render
    page.should_not have_admin_button
  end

  it 'has a deactivate button' do
    render
    page.should have_deactivate_button
  end

  it 'does not have a deactivate button for a user who does not have that capability' do
    cannot(:deactivate, user)
    render
    page.should_not have_deactivate_button
  end

  def have_grant_credit_button
    have_css("[data-target='#grant_credit-modal']")
  end

  def have_manage_suggestions_button
    have_css("[data-target='#manage_suggestions-modal']")
  end

  def have_autofollow_button
    have_css("[data-action='autofollow-on']")
  end

  def have_superuser_button
    have_css("[data-action='superuser-on']")
  end

  def have_admin_button
    have_css("[data-action='admin-on']")
  end

  def have_deactivate_button
    have_css('[data-action=deactivate]')
  end
end

require "spec_helper"

describe "admin/users/index" do
  let(:page) { Capybara::Node::Simple.new(rendered) }
  let(:users) { stub_paginated_array }
  let(:viewer) { stub_user 'Peeta' }

  before do
    act_as_rfb(viewer)
    assign(:users, users)
  end

  context 'a user who can create users' do
    before { can(:create, User) }

    it 'has a new button' do
      render
      page.should have_new_button
    end
  end

  context 'a user who cannot create users' do
    before { cannot(:create, User) }

    it 'does not have a new button' do
      render
      page.should_not have_new_button
    end
  end

  def have_new_button
    have_css('[data-action=new]')
  end
end

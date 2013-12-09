require './acceptance/spec_helper'

feature 'Sending a price alert message to a Facebook user', js: true do
  let!(:user) { FactoryGirl.create(:registered_user) }
  let!(:listing) { FactoryGirl.create(:active_listing) }

  background do
    # make sure there's at least one liked listing so the notification will be sent
    given_like(listing, user)

    # rather than go through all the rigamarole of logging in as the user and connecting it to FB so that there's a
    # Rubicon profile, just stub out the Rubicon bits. yeah, that doesn't make it a full-on acceptance test, but it
    # does ensure that the job is enqueued.
    profile = stub('profile', id: '0000123456789', person_id: user.person.id)
    User.any_instance.stubs(:for_network).with(Network::Facebook).returns(profile)
    Rubicon::FacebookProfile.stubs(:find).with(profile.id, is_a(Hash)).returns(profile)

    # makes sure the job completes successfully
    profile.expects(:post_notification)

    login_as 'roslin@galactica.mil', admin: true
  end

  scenario 'happily' do
    visit admin_facebook_price_alerts_path
    send_individual_message
    message_should_be_sent
  end

  def send_individual_message
    within('#new-individual-message') do
      fill_in('message_query', with: user.name)
      find("li.active a").click # assumes a unique name
      find('button').click
    end
  end

  def message_should_be_sent
    expect(page).to have_content(user.formatted_email) # in the flash
  end
end

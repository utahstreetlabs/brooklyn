module LoggedInHomeIntegrationHelpers
  def listings_feed_check_for_new
    page.execute_script("window.TEST.trigger('feed:poll')")
    wait_a_sec_for_selenium
  end

  def refresh_listings_feed(expected_action_count=nil)
    listings_feed_check_for_new
    wait_a_while_for do
      refresh_button = page.find(:css, '#refresh-container > a')
      refresh_button.should have_content("#{expected_action_count}") if expected_action_count
      refresh_button.click()
      page.find(:css, ".product-card-v3")
    end
  end

  def decline_to_add_copious_to_facebook_timeline
    within_timeline_message_box do
      page.should have_content('Add Copious to your Facebook Timeline')
      click_link "No Thanks"
      wait_for(2)
    end
  end

  def add_copious_to_facebook_timeline
    within_timeline_message_box do
      page.should have_content('Add Copious to your Facebook Timeline')
      click_link "Try Now"
    end
  end

  def timeline_message_box_should_not_be_visible
    page.should_not have_selector("[data-role='timeline-content']", visible: true)
  end

  shared_context "curated user" do
      let!(:curated_user) { given_registered_user(name: 'Bustin Jieber') }
      before { Brooklyn::Application.config.users.signup.stubs(:curated).returns([curated_user.email]) }
  end

  shared_context "join stories" do
    let(:join_stories_count) { 0 }
    let!(:joiner) { given_registered_user(name: 'Obi Wan') }
    before do
      join_stories_count.times do
        joiner = given_registered_user(name: 'Obi Wan')
        given_joined_story(joiner, [user])
      end
    end
  end

  shared_context "users with follow relationships" do
    let!(:followee_followee) { given_registered_user(name: 'Darth', firstname: 'Anakin') }
    let!(:followee) { given_registered_user(name: 'Yoda', email: "yoda@nowhere.dagoba.sys") }
    let!(:user) { given_registered_user }
    let!(:follower) { given_registered_user(name: 'C3P0') }
    before do
      follower.follow!(user)
      user.follow!(followee)
      followee.follow!(followee_followee)
    end
  end

  def within_timeline_message_box(&b)
    within("[data-role='timeline-content']", &b)
  end
end

RSpec.configure do |config|
  config.include LoggedInHomeIntegrationHelpers
end

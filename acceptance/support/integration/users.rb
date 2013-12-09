module UserIntegrationHelpers
  EMAIL = 'hamman@ham.com'
  PASSWORD = 'hamburgersRgreat'

  def complete_full_registration
    wait_a_sec_for_selenium
    should_be_on_registration_page
    fill_in 'user_email', with: EMAIL
    fill_in 'user_password', with: PASSWORD
    modal_save = all('#new-profile-modal button[data-save=modal]', visible: true).first
    if modal_save
      modal_save.click
    else
      click_button 'Create Your Profile'
    end
    # create profile submission may happen asyncronously, so wait until the user is created to continue
    retry_with_sleep { self.current_user = User.find_by_email!(EMAIL) }
  end

  def login
    wait_a_sec_for_selenium
    fill_in 'user_email', with: EMAIL
    fill_in 'user_password', with: PASSWORD
    click_button 'Log in'
    self.current_user = User.find_by_email!(EMAIL)
  end

  def register_with_twitter
    given_twitter_profile
    visit root_path
    click_twitter_connect
    complete_full_registration
  end

  def wait_for_and_click_selector(selector)
    retry_expectations do
      expect(page).to have_css(selector, visible: true)
      find(selector).click
    end
  end

  def click_facebook_signup
    wait_for_and_click_selector('[data-action=auth-facebook][data-signup=true]')
  end

  def click_facebook_connect
    wait_for_and_click_selector('[data-action=auth-facebook][data-primary=true]')
  end

  def click_twitter_signup
    wait_for_and_click_selector('[data-action=auth-twitter][data-signup=true]')
  end

  def click_twitter_connect
    wait_for_and_click_selector('[data-action=auth-twitter][data-primary=true]')
  end

  def should_be_on_home_page
    retry_expectations { current_path.should == root_path }
  end

  def should_be_on_registration_page
    wait_a_while_for do
      page.find(:css, '.create-account-wrapper')
    end
  end

  def should_be_on_profile_page(user)
    retry_expectations { current_path.should == public_profile_path(user) }
  end

  def click_profile_follow_button
    within '[data-role=profile-follow-box]' do
      follow = nil
      wait_a_while_for do
        follow = page.find('[data-action=follow]')
      end
      follow.click
      wait_a_while_for do
        page.find('[data-action=unfollow]')
      end
    end
  end

  def click_profile_unfollow_button
    within '[data-role=profile-follow-box]' do
      unfollow = nil
      wait_a_while_for do
        unfollow = page.find('[data-action=unfollow]')
      end
      unfollow.click
      wait_a_while_for do
        page.find('[data-action=follow]')
      end
    end
  end

  def click_profile_block_button
    within '[data-role=profile-block-box]' do
      block = nil
      wait_a_while_for do
        block = page.find('[data-role=block]')
      end
      block.click
      wait_a_while_for do
        page.find('[data-role=unblock]')
      end
    end
  end

  def user_should_not_be_autofollowed(user)
    user.reload
    user.autofollow.should_not be
  end

  def user_should_be_autofollowed(user)
    user.reload
    user.autofollow.should be
  end

  def signup_modal_id
    'signup'
  end

  def signup_modal_should_be_visible
    modal_should_be_visible(signup_modal_id)
  end

  def signup_modal_should_not_exist
    modal_should_not_exist(signup_modal_id)
  end
end

RSpec.configure do |config|
  config.include UserIntegrationHelpers
end

RSpec::Matchers.define :have_connect_buttons do |key|
  match do |page|
    page.has_css?('.sns-connect')
  end
end

RSpec::Matchers.define :have_followers_count do |count|
  match do |page|
    page.find('[data-role=profile-followers-count]').text.strip.to_i == count
  end
end

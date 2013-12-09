module NetworksHelpers
  # go through the standard omniauth connection flow
  def connect_to(name)
    click_link "Connect my #{name}"
    wait_a_sec_for_selenium
    accept_insane_gdp_facebook_permissions if name == 'Facebook'
  end

  def connection_should_succeed(name)
    expect(page).to have_content("You are now connected to #{name}")
  end

  def network_settings_should_be_updated(name)
    expect(page).to have_content("Your #{name} settings have been updated")
  end
end

RSpec.configure do |config|
  config.include NetworksHelpers
end

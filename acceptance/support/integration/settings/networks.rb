module Settings::NetworksHelpers
  shared_context 'viewing networks settings' do
    before do
      login_as "starbuck@galactica.mil"
      visit settings_networks_path
    end

    def connect_to(network, name)
      within ".network-setting-#{network}" do
        click_link "Connect #{name}"
      end
    end

    def connection_should_succeed(name)
      expect(current_path).to eq(settings_networks_path)
      expect(page).to have_content("You are now connected to #{name}")
    end

    def disconnect_from(network, name)
      within ".network-setting-#{network}" do
        click_link "Disconnect"
      end
    end

    def disconnection_should_succeed(name)
      expect(current_path).to eq(settings_networks_path)
      expect(page).to have_content("You are now disconnected from #{name}")
    end

    def save_network_settings(network)
      within ".network-setting-#{network}" do
        click_button "Save Changes"
      end
    end
  end
end

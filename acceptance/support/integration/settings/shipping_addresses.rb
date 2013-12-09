module Settings::ShippingAddressesHelpers
  shared_context 'viewing shipping settings' do
    before do
      viewer = login_as "starbuck@galactica.mil"
      @address = given_shipping_address viewer
      visit settings_shipping_addresses_path
    end

    def add_shipping_address
      click_link "Add a shipping address"
      within '#new-address' do
        fill_in "Name:", with: "Home"
        fill_in "Street Address:", with: "10 Adama Blvd"
        fill_in "City:", with: "Caprica"
        select "California", from: "State:"
        fill_in "Zip Code:", with: "94117"
        fill_in "Phone Number:", with: "555-555-5555"
        click_button "Save New Address"
      end
    end

    def shipping_address_creation_should_succeed
      expect(flash_notice).to have_content("Your shipping address has been added")
      expect(page).to have_content("Home")
      expect(page).to have_content("10 Adama Blvd")
    end

    def update_shipping_address
      within "#edit-address-#{@address.id}" do
        click_link "Edit"
        fill_in "Name:", with: "Home"
        fill_in "Street Address:", with: "10 Adama Blvd"
        fill_in "City:", with: "Caprica"
        select "California", from: "State:"
        fill_in "Zip Code:", with: "94117"
        fill_in "Phone Number:", with: "555-555-5555"
        click_button "Save Changes"
      end
    end

    def shipping_address_update_should_succeed
      expect(flash_notice).to have_content("Your shipping address has been updated")
      expect(page).to have_content("Home")
      expect(page).to have_content("10 Adama Blvd")
    end

    def delete_shipping_address
      within "#edit-address-#{@address.id}" do
        click_link "Delete"
      end
      wait_for(2)
      accept_alert
    end

    def shipping_address_delete_should_succeed
      expect(flash_notice).to have_content("Your shipping address has been removed")
    end

    def set_default_shipping_address
      last_address = current_user.postal_addresses.last
      within "#edit-address-#{last_address.id}" do
        click_link "Make Default"
      end
    end

    def shipping_address_default_should_succeed
      retry_expectations do
        last_address = current_user.reload.postal_addresses.last
        expect(last_address.default_address).to be_true
      end
    end

    def shipping_address_default_should_be_first
      first_address, last_address = current_user.postal_addresses.all
      expect(first_address).to_not be_default_address
      expect(last_address).to be_default_address
      expect(first_address).to be_in_address_position 2
      expect(last_address).to be_in_address_position 1
    end

    def shipping_addresses_include(a)
      page.has_css?("#edit-address-#{a.id}")
    end

    RSpec::Matchers.define :be_default_address do
      match do |address|
        address.default_address
      end
    end

    # this is a bit nuts, but nokogiri's nth-of-type seems to be very broken
    # and the shipping address page is full duplicate ids, so we test an xpath
    # expression and return false if it's not found
    RSpec::Matchers.define :be_in_address_position do |number|
      match do |address|
        begin
          find(:xpath,
               "//div[@id='edit-addresses']/form[@id='edit_user_1' and position()=#{number}]" +
               "/*[@id='edit-address-#{address.id}']")
          true
        rescue Capybara::ElementNotFound
          false
        end
      end
    end
  end
end

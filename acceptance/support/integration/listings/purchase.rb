module Listings::PurchaseHelpers
  shared_context 'purchasing a listing' do
    before do
      login_as 'starbuck@galactica.mil'
      visit listing_path(listing)
    end

    def buy_button
      find('[data-action=buy]')
    end

    def begin_purchase
      buy_button.click
      wait_a_sec_for_selenium
    end

    def should_be_on_shipping_page(listing)
      wait_a_while_for do
        page.has_css?('#ship-to').should be_true
      end
      current_path.should == shipping_listing_purchase_path(listing)
    end

    def choose_shipping_address(address)
      within '#ship-to' do
        choose address.name
      end
    end

    def fill_in_shipping_information(options = {})
      fill_in 'Name:', :with => 'Home'
      fill_in 'Street Address:', :with => '157 Bedford Ave Apt 4'
      fill_in 'City:', :with => 'Brooklyn'
      select 'New York', :from => 'State:'
      fill_in 'Zip Code:', :with => '11211'
      fill_in 'Phone Number:', :with => '(718) 555-1212'
      if options[:bill_to_shipping]
        bill_to_shipping
      end
      click_on 'Save address and Continue to Payment'
    end

    def bill_to_shipping
      within '#new-address' do
        check 'postal_address_shipping_address_bill_to_shipping'
      end
    end

    def check_same_as_shipping_address
      within '#new_purchase' do
        check 'purchase_bill_to_shipping'
      end
    end

    def apply_credit(amount)
      fill_in 'credit_amount', with: amount
      click_button 'Apply Credit'
    end

    def credit_should_be_applied(listing, amount)
      applied = sprintf "%0.2f", amount
      total = sprintf "%0.2f", listing.total_price - amount
      retry_expectations { expect(find('#credit')).to have_content(applied) }
      expect(find('#total-price')).to have_content(total)
    end

    def continue_to_payment
      within '#ship-to' do
        click_on 'Continue to Payment'
      end
    end

    def should_be_on_payment_page(listing)
      wait_a_while_for do
        page.has_css?('#payment').should be_true
      end
      current_path.should == payment_listing_purchase_path(listing)
    end

    def shipping_address_should_be_shown(address)
      within '#shipping-address-details' do
        find('.ship-to-name').text.should == address.name
      end
    end

    def edit_order_details
      within '#buyer-price-details' do
        click_on 'Edit'
        wait_a_sec_for_selenium
      end
    end

    def edit_shipping_address
      within '#shipping-address-details' do
        click_on 'Edit'
        wait_a_sec_for_selenium
      end
    end

    def fill_in_credit_card_information(options = {})
      fill_in 'purchase_cardholder_name', with: current_user.name
      fill_in 'purchase_card_number', with: options.fetch(:card_number, '4111111111111111')
      fill_in 'purchase_security_code', with: '123'
      select (Date.today.year + 1).to_s, from: 'purchase_expires_on_1i'
    end

    def fill_in_billing_information
      fill_in 'purchase_line1', with: '164 Townsend St'
      fill_in 'purchase_line2', with: 'Suite 6'
      fill_in 'purchase_city', with: 'San Francisco'
      select 'California', from: 'purchase_state'
      fill_in 'purchase_zip', with: '94107'
      fill_in 'purchase_phone', with: '(415) 555-1212'
    end

    def purchase_button
      within('#payment') do
        find('button[type=submit]')
      end
    end

    def submit_purchase_form
      purchase_button.click
    end

    def purchase_form_should_not_be_submittable
      purchase_button['disabled'].should be
    end

    def card_should_be_invalid
      page.should have_flash_message(:alert, 'purchase.card_not_validated')
    end

    def card_should_be_rejected
      page.should have_flash_message(:alert, 'purchase.payment_rejected')
    end

    def card_should_be_declined
      page.should have_flash_message(:alert, 'purchase.payment_declined')
    end
  end
end

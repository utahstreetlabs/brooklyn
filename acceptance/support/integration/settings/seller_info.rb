module Settings::SellerInfoHelpers
  shared_context 'viewing seller identity settings' do
    before do
      # need to use a unique email address on every test run to make sure that the test user does not have a
      # balanced account saved in the test marketplace from a previous test in the suite
      login_as "starbuck-#{Time.now.to_i}@galactica.mil"
      visit settings_seller_identity_path
    end

    def fill_in_identity_details(options = {})
      more_info_required = options[:simulate_more_information_required]
      fill_in 'identity_name', with: 'Kara Thrace'
      fill_in 'identity_street_address', with: 'Deck 6, Battlestar Galactica'
      fill_in 'identity_postal_code', with: (more_info_required ? '99999' : '11111')
      fill_in 'identity_phone_number', with: '(555) 555-1212'
      page.execute_script "$('#identity_region').val('EX')" if more_info_required
    end

    def submit_identity_form
      find('[data-button=identity-save]').click
    end

    def identity_should_be_validated
      retry_expectations { current_path.should == new_settings_seller_account_path }
      current_user.reload
      current_user.should be_balanced_merchant
    end

    def form_should_show_errors
      page.should have_css('#field_name.error')
    end

    def form_should_require_more_information
      page.should have_flash_message(:alert, 'settings.seller.identity.attempt2')
    end

    def form_should_require_more_information_again
      page.should have_flash_message(:alert, 'settings.seller.identity.attempt3',
                                     help_link: Brooklyn::Application.config.email.to.help)
    end

    def form_should_reject_invalid_identity
      # in this case, the controller renders the failure template, which there's no simple way to identify other
      # than looking for a specific piece of content
      page.should have_content(I18n.t('settings.seller.identity.failure.header'))
    end
  end
end

require './acceptance/spec_helper'

feature "Create listings" do
  let! :handbags do
    given_category "Handbags"
  end

  let! :action_figures do
    given_category "Action Figures"
  end

  let! :medium_size do
    given_size_tag "Medium"
  end

  include_context 'mock twitter profile'
  include_context 'mock instagram profile'

  background do
    given_tags ["leather", 'lovable']
    given_dimension "Condition", category: handbags, values: [
      "New with tags", "New without tags", "Used - excellent", "Used - fair"
    ]
  end

  context "with facebook mock users" do
    include_context 'viewing my dashboard'

    scenario "successful listing with free basic shipping", js: true do
      click_sell
      fill_in_listing_form do
        enter_shipping_amount 0.00
        choose_basic_shipping
      end
      publish_listing_should_succeed
      created_listing.reload
      created_listing.price.should == 400
      created_listing.shipping.should == 0
      created_listing.should be_basic_shipping
    end

    scenario "successful listing with non-free basic shipping", js: true do
      click_sell
      fill_in_listing_form do
        enter_shipping_amount 10.00
        choose_basic_shipping
      end
      publish_listing_should_succeed
      created_listing.reload
      created_listing.price.should == 400
      created_listing.shipping.should == 10
      created_listing.should be_basic_shipping
    end

    scenario "successful listing with free prepaid shipping", js: true do
      click_sell
      fill_in_listing_form do
        enter_shipping_amount 0.00
        choose_prepaid_shipping :medium_box
      end
      publish_listing_should_succeed
      created_listing.reload
      created_listing.price.should == 400
      created_listing.shipping.should == 0
      created_listing.should be_prepaid_shipping
    end

    scenario "successful listing with non-free prepaid shipping", js: true do
      click_sell
      fill_in_listing_form do
        enter_shipping_amount 10.00
        choose_prepaid_shipping :medium_box
      end
      publish_listing_should_succeed
      created_listing.reload
      created_listing.price.should == 400
      created_listing.shipping.should == 10
      created_listing.should be_prepaid_shipping
    end

    scenario "successful listing with new collection", js: true do
      pending "fails on office, no one knows why."
      click_sell
      fill_in_listing_form
      listing_page_create_new_collection('bacon')
      publish_listing_should_succeed
      created_listing.reload
      expect(created_listing.collections.map(&:name)).to eq(['bacon'])
    end

    scenario "successful listing with handling", js: true do
      click_sell
      fill_in_listing_form do
        set_handling_time('10 days')
      end
      publish_listing_should_succeed
      page.should have_content('10 days to ship')
    end

    scenario 'successful listing with new brand', js: true do
      click_sell
      fill_in_listing_form do
        set_brand('A new brand not listed', create: true)
      end
      publish_listing_should_succeed
      created_listing.reload
      created_listing.brand_name.should == 'A new brand not listed'
    end

    scenario "edit before preview", js: true do
      click_sell
      fill_in_listing_form
      submit_listing_form
      retry_expectations { expect(current_path).to eq(listing_path(created_listing)) }
      find('[data-action=edit]').click
      retry_expectations { expect(current_path).to eq(edit_listing_path(created_listing)) }
      click_button "preview_listing"
      page.should have_content(I18n.t('listings.show.seller.status.inactive'))
      page_should_not_have_share_buttons
    end

    scenario "save draft", js: true do
      click_sell
      fill_in 'listing_price', with: '10'
      submit_draft_form
      current_path.should == setup_listing_path(created_listing)
      visit dashboard_path
      click_link "Draft"
      find('[data-action=view-listing]').click
      wait_a_sec_for_selenium
      page.should have_content "$10.00"
    end

    scenario "no input", js: true do
      click_sell
      # oddness in the selenium driver
      # see: https://github.com/jnicklas/capybara/issues/705
      find("#preview_listing")['disabled'].should == "true"
      submit_listing_form
      current_path.should == setup_listing_path(created_listing)
    end

    scenario "original price cannot be greater than price", js: true do
      click_sell
      fill_in_listing_form do
        enter_shipping_amount 0.00
        enter_original_price 1.00
        choose_basic_shipping
      end
      submit_listing_form
      page.should have_content("Your changes were not saved. See the errors below")
    end

    scenario "original price cannot be greater than price", js: true do
      click_sell
      fill_in_listing_form do
        enter_shipping_amount 0.00
        enter_original_price 699.00
        choose_basic_shipping
      end
      publish_listing_should_succeed
    end

    context "when uploading photos" do
      before { click_sell }

      scenario "upload photo should succeed and show photos", js: true do
        page.should_not have_photos
        upload_photo "handbag.jpg"
        page.should have_photos
      end

      context "with one photo uploaded" do
        before { upload_photo "handbag.jpg" }

        scenario "deleting a photo should succeed", js: true do
          delete_photo
          accept_alert
          wait_for(3)
          page.should_not have_photos
        end

        scenario "updating the photo should succeeed", js: true do
          images.first['src'].should =~ /handbag.jpg/
          update_photo
          refresh_page
          images.first['src'].should =~ /zach.jpg/
        end

        def update_photo
          # move the hidden form into view - selenium can't click it otherwise
          page.execute_script("$('.photo-update-forms').css('left', '0px')")
          # fill the now-unhidden form in manually
          fill_in 'listing_photo_remote_file_url', with: 'https://s3.amazonaws.com/utahstreetlabs-dev-utah/images/zach.jpg'
          # submit the now-unhidden form
          click_button 'Update Listing photo'
        end

        def refresh_page
          current_url = page.current_url
          visit root_path
          visit current_url
        end
      end

      context "with two photos uploaded" do
        before do
          upload_photo "handbag.jpg"
          sleep 1
          upload_photo "hambag.jpg"
          sleep 1
        end

        scenario "the first upload should be the primary image", js: true do
          handbag_should_be_primary_image
        end

        scenario "sorting an image to head of this list should make it the primary image", js: true do
          move_second_image_to_front
          hambag_should_be_primary_image
        end

        def move_second_image_to_front
          # sortable manipulation is known to be a PITA with capybara, so do this manually:
          # https://github.com/jnicklas/capybara/issues/222
          page.execute_script("$('.sortable').trigger('reorder-to', [$($('.sortable li')[1]), 1])")
          sleep 2
        end
      end
    end

    context "when importing photos" do
      before do
        stub_get_instagram_photos
        click_sell
      end

      context "when not connected to instagram" do
        scenario "when connection fails", js: true do
          User.any_instance.stubs(:add_identity_from_oauth).raises(ConnectionFailure)
          page.should be_able_to_connect_to_instagram
          open_instagram_modal
          wait_a_while_for do
            flash_alert.should have_content("Could not connect to network")
          end
        end

        scenario "import photo should succeed and show photos", js: true do
          page.should be_able_to_connect_to_instagram
          upload_photo_from_instagram(0)
          page.should have_photo("small_batman.jpg")
        end
      end

      context "when connected to instagram" do
        include_context "connected to instagram"

        before do
          click_sell
        end

        scenario "import photo should succeed and show photos", js: true, flakey: true do
          page.should_not be_able_to_connect_to_instagram
          page.should be_able_to_upload_from_instagram
          upload_photo_from_instagram(0)
          page.should have_photo("small_batman.jpg")
        end

        scenario "scrolling to bottom of overlay should load more photos", js: true do
          page.should_not be_able_to_connect_to_instagram
          page.should be_able_to_upload_from_instagram
          open_instagram_import_overlay
          scroll_overlay_to_bottom
          wait_for_new_photo(2)
          click_import_photo(2)
          close_import_overlay
          page.should have_photo("small_zach.jpg")
        end
      end
    end
  end

  context "when sharing on Facebook" do
    include_context "with facebook test user"
    let(:email) { "starbuck@galactica.mil" }
    # set this up specifically so it will be found in `login_as` below and prevent mocking a new fb user
    let!(:user) { FactoryGirl.create(:registered_user, email: email, balanced_url: nil) }

    before do
      visit root_path
      fb_user_login fb_user, return_to: root_path
      login_as email
      visit dashboard_path
    end

    scenario "when user has hooked up their account to timeline", js: true do
      given_eligible_for_timeline(false)
      click_sell
      fill_in_listing_form
      publish_listing_should_succeed
      page_should_not_have_share_link(:facebook)
    end
  end

  def created_listing
    Listing.last || raise("No listings!")
  end

  def handbag_should_be_primary_image
    images.first['src'].should =~ /handbag.jpg/
    images[1]['src'].should =~ /hambag.jpg/
  end

  def hambag_should_be_primary_image
    images.first['src'].should =~ /hambag.jpg/
    images[1]['src'].should =~ /handbag.jpg/
  end

  def move_second_image_to_front
    # sortable manipulation is known to be a PITA with capybara, so do this manually:
    # https://github.com/jnicklas/capybara/issues/222
    page.execute_script("$('.sortable').trigger('reorder-to', [$($('.sortable li')[1]), 1])")
    sleep 2
  end

  def images
    all(".photo-list img")
  end

  def sortables
    all("#product-photos .items li")
  end

  def click_sell
    visit dashboard_path
    click_link "Create a Listing"
  end

  def delete_photo
    find(".btn-delete").click
  end

  def submit_listing_form
    find("#preview_listing").click
  end

  def submit_draft_form
    click_button "save_draft"
  end

  def click_publish_listing
    find('[data-action=activate]').click
  end

  def publish_listing_should_succeed
    submit_listing_form
    retry_expectations { current_path.should == listing_path(created_listing) }
    page.should have_content(I18n.t('listings.show.seller.status.inactive'))

    click_publish_listing
    retry_expectations { current_path.should == listing_path(created_listing) }
    page.should have_content(I18n.t('listings.show.seller.status.active'))
    page.should have_css('[data-role=active-listing-cta]')
  end

  def upload_photo(file)
    prepare_for_photo_upload
    attach_file "listing_photo_file", fixture(file)
  end

  def add_copious_to_facebook_timeline
    page.should have_content('Add Copious to your Facebook Timeline')
    click_link "Try Now"
  end

  def page_should_not_have_share_link(network)
    page.should_not have_content(I18n.t(network, scope: "listings.share.message"))
  end

  matcher :have_photo do |filename|
    match do |page|
      with_obsolete_element_retry do
        page.find("#product-photos img[src*='#{filename}']", :visible => true).present?
      end
    end
  end

  matcher :have_photos do
    match do |page|
      with_obsolete_element_retry do
        begin
          page.find("#product-photos img", :visible => true)
        rescue Capybara::ElementNotFound
          false
        end
      end
    end
  end
end

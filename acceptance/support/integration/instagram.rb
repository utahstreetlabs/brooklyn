module InstagramIntegrationHelpers

  shared_context "connected to instagram" do
    before do
      visit dashboard_path
      connect_to 'Instagram'
      connection_should_succeed 'Instagram'
    end
  end

  RSpec::Matchers.define :be_able_to_connect_to_instagram do
    match do |page|
      with_obsolete_element_retry do
        page.has_css?('.connect-instagram', :visible => true)
      end
    end
  end

  RSpec::Matchers.define :be_able_to_upload_from_instagram do
    match do |page|
      with_obsolete_element_retry do
        page.has_css?('.upload-instagram', :visible => true)
      end
    end
  end

  def stub_get_instagram_photos
    # Only return 2 photos; there's a selenium bug that results in a MoveTargetOutOfBoundsError
    # if we have too many photos displayed and search for the close element
    imgs_ary = (1..2).inject([]) do |m,n|
      m += ["{\"id\":\"121#{n}\",\"images\":{\"standard_resolution\":{\"url\":\"https://s3.amazonaws.com/utahstreetlabs-dev-utah/images/batman.jpg\"},\"low_resolution\":{\"url\":\"https://s3.amazonaws.com/utahstreetlabs-dev-utah/images/batman.jpg\"}}}"]
    end
    stub_request(:get, /users\/\w*\/media\/recent.*count=15/).
      to_return(status: 200, headers: {'Content-Length' => 0, 'Content-Type' => 'text/javascript; charset=UTF-8'}, :body => "{\"data\":[#{imgs_ary.join(',')}]}")
    stub_request(:get, /users\/\w*\/media\/recent.*count=12/).
      to_return(status: 200, headers: {'Content-Length' => 0, 'Content-Type' => 'text/javascript; charset=UTF-8'}, :body => "{\"data\":[{\"id\":\"1221\",\"images\":{\"standard_resolution\":{\"url\":\"https://s3.amazonaws.com/utahstreetlabs-dev-utah/images/zach.jpg\"},\"low_resolution\":{\"url\":\"https://s3.amazonaws.com/utahstreetlabs-dev-utah/images/zach.jpg\"}}}]}")
  end

  def scroll_overlay_to_bottom
    page.execute_script("$('#instagram-modal .modal-body').prop({ scrollTop: $(\"#instagram-modal .modal-body\").prop(\"scrollHeight\") })")
    sleep 2
    page.execute_script("$('#instagram-modal .modal-body').trigger(\"scroll\")")
    sleep 2
  end

  # Note that execute_script uses a 0-indexed array for elements, but selenium css
  # selectors for nth-of-type are 1-indexed.  So for consistency we use a 0-index
  # everywhere and just +1 when dealing with selenium css selectors.
  def click_import_photo(n)
    page.execute_script("$($('div.instagram-import-wrap a.button')[#{n}]).click()")
    sleep 2
    wait_a_while_for do
      page.find("ul#instagram-photos li:nth-of-type(#{n+1}):contains('Imported')")
    end
  end

  def wait_for_new_photo(n)
    wait_a_while_for do
      page.find("ul#instagram-photos li:nth-of-type(#{n+1})")
    end
  end

  def close_import_overlay
    wait_a_while_for do
      page.execute_script("$('#instagram-modal').modal(\"hide\")")
      wait_a_sec_for_selenium
    end
  end

  def open_instagram_modal
    # we use multiple links here depending on user state, but only one is visible at a time.
    find('#upload-instagram a', visible: true).click
  end

  def open_instagram_import_overlay
    open_instagram_modal
    retry_expectations do
      expect(page).to have_css('#instagram-modal', :visible => true)
    end
    retry_expectations do
      expect(page).to have_css("ul#instagram-photos li:nth-of-type(1):contains('Import')")
    end
    bootstrap_modal_should have_content("IMPORT INSTAGRAM PHOTOS")
  end

  def upload_photo_from_instagram(n)
    open_instagram_import_overlay
    click_import_photo(n)
    close_import_overlay
  end
end


RSpec.configure do |config|
  config.include InstagramIntegrationHelpers
end

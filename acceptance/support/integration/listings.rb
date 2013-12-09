module ListingIntegrationHelpers
  def should_be_on_listing_page(listing)
    current_path.should == listing_path(listing)
  end

  def autocomplete_click(selector)
    retry_expectations { page.should have_selector(selector) }
    page.execute_script " $('#{selector}').trigger(\"mouseenter\").click();"
  end

  def prepare_for_photo_upload
    # Because we're using attach_file instead of going through the file uploader
    # we want to make listing_photo_file visible (it won't be normally until
    # we already have a photo attached)
    retry_expectations { expect(page).to have_css("[data-role='photo-list-section']") }
    page.execute_script("$(\"[data-role='photo-list-section']\").attr('style', \"\")")
    wait_a_sec_for_selenium
  end

  #
  # Create/edit
  #

  def attach_listing_photo
    work = lambda { attach_file "listing_photo_file", "#{Rails.root}/spec/fixtures/handbag.jpg" }
    work.call
  rescue Selenium::WebDriver::Error::ElementNotVisibleError
    # just try again
    sleep 3
    work.call
  end

  def set_combo(id, name, options = {})
    input = find(id).find("input")
    # if we're creating, there's no match so we want to type the whole name
    input.set(options[:create] ? name : name[0..2])
    autocomplete_click(".dropdown-menu a:contains(\"#{name[1..-1]}\")")
    retry_expectations { input.value.should == name }
  end

  def set_size(name)
    set_combo("#field_size_name", name)
  end

  def set_medium_size
    set_size("Medium")
  end

  # set options[:create] to allow creation of new brands
  def set_brand(name, options = {})
    set_combo('#field_brand_name', name, options)
  end

  def fill_in_listing_form(replacements={})
    prepare_for_photo_upload
    attach_listing_photo

    fill_in "Listing title", with: replacements.fetch(:title, "Marc Jacobs Rio Satchel")

    description = replacements.fetch(:description, <<-EOS.gsub("'", "\\'").gsub("\n", "\\n"))
      I bought this Marc Jacobs bag at Bloomingdales. Turned out to be a bit too
      big for me, so I'm willing to part with it. Includes the dust bag and the
      badge of authenticity. You can see a photo of the receipt in the images.
      Has a small amount of wear on the handles from 1 month of use, but
      otherwise is like new.
    EOS
    page.driver.browser.execute_script("$('#listing_description').data('wysiwyg').setContent('#{description}');")
    select replacements.fetch(:category, "Handbags"), from: "listing_category_id"

    select replacements.fetch(:condition, "Used - excellent"), from: "listing_dimensions_condition"

    set_medium_size

    #the autocompleter creates it's own field "#listing_tags_tag" which is where the user enters text
    #the real field that the backend cares about is "#listing_tags", which the autocompleter populates
    #the comma after satchel, forces the autocomplete
    fill_in "listing_tags_tag", with: replacements.fetch(:tags, "satchel,")
    fill_in "listing_tags_tag", with: "leather,"

    find_field("listing_tags").value.should == "satchel,leather"

    fill_in "listing_price", with: replacements.fetch(:price, 400.00)

    yield if block_given?
  end

  def enter_shipping_amount(amount)
    fill_in "listing_shipping", with: amount.to_s
    # There's a JS timing issue with filling in the shipping price.  Occasionally
    # the browser will fail to untick the value for 'Free Shipping'.
    # This forces the value to untick.  Not sure if this should be here, as it
    # introduces behavior not explictly defined by the tested page.
    if amount.to_i > 0
      page.execute_script("$('#listing_free_shipping').prop('checked',false)")
    end
  end

  def choose_prepaid_shipping(code)
    id = "listing_shipping_option_code_#{code}"
    expect(page).to have_css("##{id}")
    choose(id)
  end

  def choose_basic_shipping
    choose "listing_shipping_option_code"
  end

  def set_handling_time(duration='10 days')
    select duration, from: 'listing_handling_duration'
  end

  def enter_original_price(amount)
    fill_in "listing_original_price", with: amount.to_s
  end

  # Show

  def report_listing_button
    find "#listing_flag"
  rescue Capybara::ElementNotFound
    nil
  end

  def seller_profile
    find ".profile"
  rescue Capybara::ElementNotFound
    nil
  end

  def seller_controls
    find ".controls"
  rescue Capybara::ElementNotFound
    nil
  end

  def post_listing_comment(text = 'This is a comment.', options = {})
    selector = '#comment_text'
    find(selector).set(text)
    send_enter_key(selector)
  end

  def reply_to_listing_comment(text = 'Yeah dogg!', options = {})
    click_on 'Reply'
    selector = '[data-role=comment-reply]'
    find(selector).set(text)
    send_enter_key(selector)
  end

  def delete_listing_comment(comment = nil)
    within comment_selector(comment) do
      wait_a_while_for do
        click_on 'Delete Comment'
      end
    end
  end

  def delete_listing_reply(reply = nil)
    within reply_selector(reply) do
      wait_a_while_for do
        click_on 'Delete Comment'
      end
    end
  end

  def flag_listing_comment(comment = nil)
    within comment_selector(comment) do
      click_on 'Flag'
      fill_in 'description', with: 'This commenter is a spammer!'
      wait_a_while_for do
        click_on 'Flag this comment'
      end
    end
  end

  def flag_listing_reply(reply = nil)
    within reply_selector(reply) do
      click_on 'Flag'
      fill_in 'description', with: 'This commenter is a spammer!'
      wait_a_while_for do
        click_on 'Flag this comment'
      end
    end
  end

  def unflag_listing_comment(comment = nil)
    within comment_selector(comment) do
      wait_a_while_for do
        click_on 'Unflag Comment'
      end
    end
  end

  def unflag_listing_reply(reply = nil)
    within reply_selector(reply) do
      wait_a_while_for do
        click_on 'Unflag Comment'
      end
    end
  end

  def comment_selector(comment = nil)
    comment ? "#listing-feed-comment-#{comment.id}" : '.listing-feed-comment'
  end

  def reply_selector(reply = nil)
    reply ? "#listing-feed-reply-#{reply.id}" : '.listing-feed-reply'
  end

  def love_listing
    find("[data-action='love']").click
  end

  def unlove_listing
    find("[data-action='unlove']").click
  end

  def page_should_not_have_share_buttons
    page.has_css?("[data-role='action-area']").should be_false
  end

  def page_should_have_share_buttons
    page.has_css?("[data-role='action-area']").should be_true
  end

  def buy_button_should_be_disabled
    page.has_css?('.buy disabled')
  end

  def size_textfield_should_be_readonly
    page.has_css?('#listing_size_name[readonly="readonly"]')
  end

  def toggle_order_details
    find("[href='#order-details-content']").click
  end

  def price
    find("[data-role=price]")[:'data-amount']
  end

  def shipping
    find("[data-role=shipping]")[:'data-amount']
  end

  # http://stackoverflow.com/questions/10866946/how-do-i-simulate-hitting-enter-in-an-input-field-with-capybara-and-chromedriver
  def send_enter_key(selector)
    find(selector).native.send_keys(:return)
  end

  RSpec::Matchers.define :have_listings do
    match do |page|
      with_obsolete_element_retry do
        begin
          page.find("#product-photos img")
        rescue Capybara::ElementNotFound
          false
        end
      end
    end
  end

  RSpec::Matchers.define :have_love_button do
    match do |page|
      with_obsolete_element_retry do
        begin
          page.find("[data-action=love]")
        rescue Capybara::ElementNotFound
          false
        end
      end
    end
  end

  RSpec::Matchers.define :have_unlove_button do
    match do |page|
      with_obsolete_element_retry do
        begin
          page.find("[data-action=unlove]")
        rescue Capybara::ElementNotFound
          false
        end
      end
    end
  end

  RSpec::Matchers.define :have_size do |name|
    match do |page|
      begin
        page.find('[data-role=listing-size]').text == name
      rescue Capybara::ElementNotFound
        false
      end
    end
  end

  RSpec::Matchers.define :have_any_size do
    match do |page|
      begin
        page.find('[data-role=listing-size]')
      rescue Capybara::ElementNotFound
        false
      end
    end
  end
end

RSpec.configure do |config|
  config.include ListingIntegrationHelpers
end

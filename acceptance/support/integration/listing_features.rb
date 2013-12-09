module ListingFeaturesIntegrationHelpers
  def remove_listing(listing)
    within "#featured-listing-#{listing.id}" do
      page.find('[data-action=delete]').click
    end
    accept_alert
  end

  def listing_should_be_gone(listing)
    within "#featured-listings" do
      page.should_not have_content(listing.title)
    end
  end

  def move_listing_to_top(listing)
    # sortable manipulation is known to be a PITA with capybara, so do this manually:
    # https://github.com/jnicklas/capybara/issues/222
    page.execute_script("$('[data-role=sortable-table] tbody').trigger('sortupdate', {item: $('#featured-listing-#{listing.id}')})")
    sleep 2
  end

  def listings_should_be_in_order(*listings)
    items = all("[data-role=featured-listing]")
    items.each_with_index do |item, index|
      item['id'].should == "featured-listing-#{listings[index].id}"
    end
  end
end

RSpec.configure do |config|
  config.include ListingFeaturesIntegrationHelpers
end

module MastheadHelpers
  shared_context 'adding via masthead' do
    def masthead_add_collection(name = 'Pork and Beans')
      open_modal(masthead_add_listing_modal_id)
      open_modal(masthead_add_collection_id) do
        fill_in('collection_name', with: name)
      end
      save_modal(masthead_add_collection_id)
      save_modal(masthead_create_listings_id)
    end

    def masthead_add_listing_manually
      open_modal(masthead_add_listing_modal_id) do
        find('#add-modal-add-listing-copious-button').click
      end
    end

    def masthead_add_listing_external_bookmarklet
      open_modal(masthead_add_listing_modal_id) do
        find('#add-modal-add-listing-external-bookmarklet-link').click
      end
    end

    def masthead_add_listing_from_web(scrapeable = true, options = {})
      category = FactoryGirl.create(:category)
      collection = FactoryGirl.create(:collection, name: 'OMG Rad Vinyl', user: current_user)

      if scrapeable
        ListingSource::Scraper.any_instance.stubs(:content).returns(external_listing_content_valid(options))
      else
        ListingSource::Scraper.any_instance.stubs(:content).raises("Boom!")
      end

      open_modal(masthead_add_listing_modal_id)
      open_modal(masthead_add_listing_from_web_modal_id) do
        fill_in('url', with: 'http://example.com/master-of-puppets-limited-edition-vinyl')
      end
      save_modal(masthead_add_listing_from_web_modal_id)

      if scrapeable
        select(category.name, from: 'listing[category_slug]')
        fill_in('listing[description]', with: '\m/')
        select_from_collection_selector(collection.slug)
        find('#listing_save').click
      end
    end

    def masthead_add_listing_modal_id
      'add'
    end

    def masthead_add_listing_from_web_modal_id
      'add-modal-add-listing-from-web'
    end

    def masthead_add_collection_id
      'collection-create'
    end

    def masthead_create_listings_id
      'collection-create-listings'
    end

    def external_listing_content_valid(options = {})
      content = <<EOT
<html>
  <head>
    <title>Master of Puppets: limited edition vinyl!</title>
  </head>
  <body>
    <p>Yours for the low price of $99.99!</p>
EOT
      if options[:space_in_filename]
        content << <<IMG
    <img src="file://spec/fixtures/hamburg|ler .jpg" height="500" width="500">
IMG
      else
        content << <<IMG
    <img src="file://spec/fixtures/hamburgler.jpg" height="500" width="500">
IMG
      end
      content << <<EOT
  </body>
</html>
EOT
    end
  end
end

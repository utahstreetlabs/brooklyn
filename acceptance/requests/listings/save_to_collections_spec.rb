require './acceptance/spec_helper'

feature 'Manage listing saves', js: true do
  before do
    login_as "boba@bountyhunters.rep"
  end

  let!(:listing) { given_listing title: "Fett's Vette", seller: "boba@bountyhunters.rep" }
  let!(:sweet_cars) { given_collection name: "Sweet Cahs", user: "boba@bountyhunters.rep" }
  let!(:sweet_spaceships) { given_collection name: "Sweet Spaceships", user: "boba@bountyhunters.rep" }

  context "from the listing page" do
    scenario 'to and from existing collections' do
      visit listing_path(listing)
      toggle_collections(sweet_cars.name, sweet_spaceships.name)
      save_to_collection_modal_should_be_hidden
      collection_should_contain_listing(sweet_cars, listing)
      collection_should_contain_listing(sweet_spaceships, listing)

      visit listing_path(listing)
      toggle_collections(sweet_spaceships.name)
      save_to_collection_modal_should_be_hidden
      collection_should_contain_listing(sweet_cars, listing)
      collection_should_not_contain_listing(sweet_spaceships, listing)
    end

    scenario 'to a new collection' do
      visit listing_path(listing)
      toggle_collections(sweet_cars.name, new: ['Songs'])
      save_to_collection_modal_should_be_hidden
      collection_should_contain_listing(sweet_cars, listing)
      collection_should_contain_listing(Collection.find_by_slug('songs'), listing)
    end

    context "from the masthead" do
      include_context 'adding via masthead'

      scenario 'to a new collection' do
        visit listing_path(listing)
        masthead_add_collection(sweet_cars.name)
        toggle_collections(sweet_cars.name)
        save_to_collection_modal_should_be_hidden
        collection_should_contain_listing(sweet_cars, listing)
      end
    end
  end

  def collection_should_contain_listing(collection, listing)
    visit public_profile_collection_path(current_user, collection)
    expect(page).to have_content(listing.title)
  end

  def collection_should_not_contain_listing(collection, listing)
    visit public_profile_collection_path(current_user, collection)
    expect(page).not_to have_content(listing.title)
  end

  def save_to_collection_modal_should_be_hidden
    modal_should_be_hidden(save_to_collection_modal_id)
  end

  def add_new_collection(name)
    fill_in 'add_collection_input[]', with: name
    page.find('[data-action=add-collection]').click
  end

  def toggle_collections(*collection_names)
    options = collection_names.extract_options!
    open_modal(save_to_collection_modal_id) do
      wait_a_sec_for_selenium
      if options[:new]
        options[:new].each do |name|
          add_new_collection(name)
        end
      end
      collection_names.each do |name|
        page.find("[data-collection=#{Collection.compute_slug(name)}]").click
      end
    end
    save_modal(save_to_collection_modal_id)
  end

  def save_to_collection_modal_id
    "listing-save-to-collection-#{listing.id}"
  end
end

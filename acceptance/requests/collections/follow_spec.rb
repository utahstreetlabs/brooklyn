require './acceptance/spec_helper'

feature 'Follow collections', js: true do
  let!(:owner) { FactoryGirl.create(:registered_user, email: "boba@bountyhunters.rep") }

  let(:listing) { given_listing title: "Fett's Vette", seller: "boba@bountyhunters.rep" }
  let(:collection) { given_collection name: "Sweet Cahs", user: "boba@bountyhunters.rep" }
  before { collection.add_listing(listing) }

  context "when the viewer is the owner" do
    let!(:viewer) { login_as "boba@bountyhunters.rep" }

    scenario 'from the listing page' do
      visit public_profile_collections_path(collection.user)
      page_should_have_edit_button(collection)
    end
  end

  context 'when the viewer is not the owner' do
    let!(:viewer) { login_as "ig88@bountyhunters.rep" }

    scenario 'from the listing page' do
      visit public_profile_collections_path(collection.user)
      page_should_have_follow_button(collection)
      follow_collection(collection)
      page_should_have_unfollow_button(collection)
      unfollow_collection(collection)
      page_should_have_follow_button(collection)
    end
  end

  def collection_card_id(collection)
    "#collection-card-#{collection.id}"
  end

  def within_collection_card(collection, &block)
    within(collection_card_id(collection), &block)
  end

  def follow_collection(collection)
    within_collection_card(collection) do
      find('[data-role=collection-follow]').click
    end
  end

  def page_should_have_edit_button(collection)
    expect(find(collection_card_id(collection))).to have_css("[data-action=edit-collection]")
  end

  def page_should_have_unfollow_button(collection)
    expect(find(collection_card_id(collection))).to have_css('[data-role=collection-unfollow]')
  end

  def unfollow_collection(collection)
    within_collection_card(collection) do
      find('[data-role=collection-unfollow]').click
    end
  end

  def page_should_have_follow_button(collection)
    expect(find(collection_card_id(collection))).to have_css('[data-role=collection-follow]')
  end
end

require './acceptance/spec_helper'

feature 'Edit collections', js: true do
  let!(:owner) { FactoryGirl.create(:registered_user, email: "anorak@oasis.sim") }

  context "when the viewer is the owner" do
    let!(:viewer) { login_as "anorak@oasis.sim" }

    context "for a system collection" do
      let!(:collection) { given_collection name: "My Favorite Oasis Things",
        editable: false, user: "anorak@oasis.sim" }

      before do
        visit public_profile_collections_path(collection.user)
      end

      scenario "update is not allowed" do
        page_should_have_collection_edit_button
        edit_collection(collection)
        page.should have_edit_collection_modal
        update_collection(collection, 'My Favorite OASIS Things')
        edit_should_not_be_allowed
      end

      scenario "delete is not allowed" do
        page_should_have_collection_edit_button
        edit_collection(collection)
        page.should have_edit_collection_modal
        delete_collection(collection)
        edit_should_not_be_allowed
      end
    end

    context "for a user-created collection" do
      let!(:collection) { given_collection name: "My Favorite Video Games 1980 to 1984",
        editable: true, user: "anorak@oasis.sim" }

      before do
        visit public_profile_collections_path(collection.user)
      end

      scenario 'update succeeds' do
        page_should_have_collection_edit_button
        edit_collection(collection)
        page.should have_edit_collection_modal
        update_collection(collection, 'My Favorite Video Games 1980 to 1989')
        dismiss_edit_success_collection_modal
        update_should_succeed
      end

      scenario "delete succeeds" do
        page_should_have_collection_edit_button
        edit_collection(collection)
        page.should have_edit_collection_modal
        delete_collection(collection)
        delete_should_succeed(collection)
      end
    end
  end
end

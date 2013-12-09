require './acceptance/spec_helper'
require 'timecop'

feature "Seller manages order with prepaid shipping" do
  let!(:order) { given_order(:confirmed) }
  let!(:shipping_option) { FactoryGirl.create(:shipping_option, listing: order.listing) }

  include_context 'selling a listing with prepaid shipping'

  background do
    order.listing.return_address = FactoryGirl.create(:shipping_address, user: order.listing.seller)
    login_as order.listing.seller.email
  end

  context 'before label has been generated' do
    context "when there is no return address" do
      before do
        order.listing.return_address = nil
        visit listing_path(order.listing)
      end

      scenario "return address is required to generate label", js: true do
        expect(page).to have_disabled_generate_label_button
        click_change_return_address
        expect(page).to have_return_address_modal
        add_return_address(FactoryGirl.build(:shipping_address))
        click_save_return_address
        expect(page).to_not have_disabled_generate_label_button
      end
    end

    context 'when editing return address', js: true do
      scenario "displays error when necessary field is blank" do
        unassigned_address = FactoryGirl.build(:shipping_address, city: nil)
        visit listing_path(order.listing)
        click_change_return_address
        expect(page).to have_return_address_modal
        expect(page).to_not have_return_address_option(unassigned_address)
        add_return_address(unassigned_address)
        click_save_return_address
        return_address_blank_error_should_be_for_field(:city)
      end

      context 'when there are existing addresses for the user' do
        let(:unassigned_address) { FactoryGirl.build(:shipping_address, name: "baz", line1: "baz st") }
        let!(:shipping_address1) { FactoryGirl.create(:shipping_address, user: order.listing.seller, name: "foo", line1: "foo st") }
        let!(:shipping_address2) { FactoryGirl.create(:shipping_address, user: order.listing.seller, name: "bar", line1: "bar st") }

        before do
          order.listing.return_address = shipping_address1
          visit listing_path(order.listing)
        end

        scenario 'choose one as the new return address' do
          click_change_return_address
          expect(page).to have_return_address_modal
          expect(page).to have_return_address_option(shipping_address1)
          expect(page).to have_return_address_option(shipping_address2)
          select_return_address(shipping_address2)
          click_save_return_address
          return_address_modal_should_be_hidden
          return_address_update_should_succeed
          return_address_should_be(shipping_address2)
        end

        scenario 'add a new address as return address' do
          click_change_return_address
          expect(page).to have_return_address_modal
          expect(page).to have_return_address_option(shipping_address1)
          expect(page).to have_return_address_option(shipping_address2)
          expect(page).to_not have_return_address_option(unassigned_address)
          add_return_address(unassigned_address)
          click_save_return_address
          return_address_modal_should_be_hidden
          return_address_creation_should_succeed
          return_address_should_be(unassigned_address)
        end
      end

      context 'when user has no existing addresses' do
        let(:unassigned_address) { FactoryGirl.build(:shipping_address, name: "baz", line1: "baz st") }

        scenario 'add a new address as return address' do
          visit listing_path(order.listing)
          click_change_return_address
          expect(page).to have_return_address_modal
          expect(page).to_not have_return_address_option(unassigned_address)
          add_return_address(unassigned_address)
          click_save_return_address
          return_address_modal_should_be_hidden
          return_address_creation_should_succeed
          return_address_should_be(unassigned_address)
        end
      end

      context "when successfully adding a new address" do
        let(:unassigned_address) { FactoryGirl.build(:shipping_address, name: "baz", line1: "baz st") }

        scenario "modal form is reset" do
          visit listing_path(order.listing)
          click_change_return_address
          expect(page).to have_return_address_modal
          add_return_address(unassigned_address)
          click_save_return_address
          return_address_modal_should_be_hidden
          click_change_return_address
          return_address_modal_fields_should_be_empty
        end
      end
    end

    scenario "view label generation instructions" do
      visit listing_path(order.listing)
      expect(page).to have_generate_label_instructions
    end

    scenario "generate label" do
      set_up_label
      visit listing_path(order.listing)
      generate_label
      expect(page).to have_download_label_instructions
    end
  end

  context "after label has been generated" do
    let!(:shipping_label) { FactoryGirl.create(:shipping_label, order: order) }

    context "before it has expired" do
      scenario "view label download instructions" do
        visit listing_path(order.listing)
        expect(page).to have_download_label_instructions
      end

      scenario "download label" do
        set_up_label_file
        visit listing_path(order.listing)
        download_label
        label_file_should_be_downloaded
      end
    end

    context "after it has expired" do
      before { shipping_label.expire! }

      scenario "and after it has expired" do
        visit listing_path(order.listing)
        expect(page).to have_label_expired_message
      end
    end
  end
end

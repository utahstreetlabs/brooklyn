require './acceptance/spec_helper'

feature 'Make an offer on a listing' do
  feature_flag('make_an_offer', true)

  let(:listing) { given_listing }

  before do
    login_as "starbuck@galactica.mil"
  end

  scenario "succeeds when I have not made an offer on this listing", js: true do
    view_listing
    make_offer_on_listing
    offer_should_be_successful
    should_not_be_able_to_make_an_offer
  end

  scenario 'is not possible when I have already made an offer on this listing' do
    given_listing_offer
    view_listing
    should_not_be_able_to_make_an_offer
  end

  def view_listing
    visit listing_path(listing)
  end

  def make_offer_on_listing
    open_modal(offer_modal_id) do
      fill_in 'offer[amount]', with: '5.00'
    end
    save_modal(offer_modal_id)
  end

  def offer_should_be_successful
    within_modal(success_modal_id) do
      page.should have_selector('a[data-dismiss=modal]')
    end
    close_modal(success_modal_id)
  end

  def should_not_be_able_to_make_an_offer
    page.should have_selector('#make-an-offer-button[disabled=disabled]')
  end

  def given_listing_offer
    FactoryGirl.create(:listing_offer, listing: listing, user: current_user)
  end

  def offer_modal_id
    'make-an-offer'
  end

  def success_modal_id
    'make-an-offer-success'
  end
end

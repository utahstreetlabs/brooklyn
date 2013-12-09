require './acceptance/spec_helper'

feature "Report listing", %q{
  In order to punish a fraudulent seller
  As a user
  I want to report the seller's listing
} do

  background do
    given_registered_user email:     "starbuck@galactica.mil",
                          firstname: "Kara",
                          lastname:  "Thrace"

    given_registered_user email:     "apollo@galactica.mil",
                          firstname: "Lee",
                          lastname:  "Adama"

    given_listings title:    "Marc Jacobs Rio Satchel",
                   category: "Handbags",
                   seller:   "apollo@galactica.mil"
  end

  let(:listing) { Listing.find_by_title("Marc Jacobs Rio Satchel") }

  scenario "report listing", js: true do
    login_as "starbuck@galactica.mil"
    visit listing_path(listing)
    find('[data-action=report]').click
    page.should have_content(I18n.t('listings.show.report_box.thanks.full'))
  end
end

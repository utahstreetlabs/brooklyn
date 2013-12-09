require './acceptance/spec_helper'

feature "view listing" do
  context "as a seller" do
    background do
      login_as "starbuck@galactica.mil"
    end

    scenario "view a listing with photos" do
      listing = given_listing(:title => "Marc Jacobs Rio Satchel",
                              :category => "Handbags",
                              :seller => "starbuck@galactica.mil",
                              :photo => "spec/fixtures/handbag.jpg")

      visit listing_path(listing)

      page_title.should have_content("Marc Jacobs Rio Satchel")
      page.should have_photo("handbag.jpg")
    end
  end

  context "as a potential buyer" do
    background do
      given_registered_user email:     "starbuck@galactica.mil",
                            firstname: "Kara",
                            lastname:  "Thrace"

      given_registered_user email:     "apollo@galactica.mil",
                            firstname: "Lee",
                            lastname:  "Adama"

      login_as "apollo@galactica.mil"
    end

    scenario "view a listing with photos" do
      listing = given_listing(:title => "Marc Jacobs Rio Satchel",
                              :category => "Handbags",
                              :seller => "starbuck@galactica.mil",
                              :photo => "spec/fixtures/handbag.jpg")

      visit listing_path(listing)

      page_title.should have_content("Marc Jacobs Rio Satchel")
      page.should have_photo("handbag.jpg")
    end

    scenario "can't view a listing without photos" do
      listing = given_listing(:title => "Marc Jacobs Rio Satchel",
                              :category => "Handbags",
                              :seller => "starbuck@galactica.mil",
                              :state => "incomplete")

      visit listing_path(listing)

      current_path.should == root_path
    end
  end

  context "for an external listing" do
    let(:seller) { FactoryGirl.create(:registered_user, email: "apollo@galactica.mil") }
    let(:listing) { FactoryGirl.create(:external_listing, seller: seller) }

    context "when viewing the listing as a buyer" do
      include_context 'purchasing a listing'

      scenario "buy button is not disabled", js: true do
        buy_button_should_not_be_disabled
      end

      def buy_button_should_not_be_disabled
        buy_button[:class].should_not =~ /disabled/
      end
    end
  end

  context "as an anonymous browser" do
    background do
      @listing = given_listing
    end

    scenario "should succeed" do
      visit listing_path(@listing)
      page_title.should have_content(@listing.title)
      page.should have_connect_buttons
    end
  end

  matcher :have_photo do |filename|
    match do |page|
      with_obsolete_element_retry do
        page.find("#photos img[src*='#{filename}']", :visible => true).present?
      end
    end
  end

  matcher :have_photos do
    match do |page|
      with_obsolete_element_retry do
        begin
          page.find("#photos img", :visible => true)
        rescue Capybara::ElementNotFound
          false
        end
      end
    end
  end
end

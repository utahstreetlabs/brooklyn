module Listings::PrepaidShippingHelpers
  shared_context 'selling a listing with prepaid shipping' do
    def set_up_label
      SHIPPING_LABELS.label = Brooklyn::ShippingLabels::Label.new(FactoryGirl.attributes_for(:shipping_label))
    end

    def generate_label
      find("[data-action=generate-label]").click
    end

    def label_file_fixture
      fixture('shipping-label.pdf')
    end

    def set_up_label_file
      SHIPPING_LABELS.label_file = File.new(label_file_fixture)
    end

    def download_label
      find("[data-action=download-label]").click
    end

    def label_file_should_be_downloaded
      # NOTE: only works for firefox. see
      # http://collectiveidea.com/blog/archives/2012/01/27/testing-file-downloads-with-capybara-and-chromedriver/
      page.response_headers["Content-Disposition"].should be
      page.source.should == File.binread(label_file_fixture)
    end

    def click_change_return_address
      find("[data-target='#return_address_change-modal']").click
    end
    
    def select_return_address(address)
      within '#ship-from' do
        choose address.name
      end
    end
    
    def click_save_return_address
      find("[data-save=modal]", visible: true).click
    end
    
    def add_return_address(address)
      within "#new_address_new" do
        fill_in 'new_address_name', :with => address.name
        fill_in 'new_address_line1', :with => address.line1
        fill_in 'new_address_city', :with => address.city
        select 'New York', :from => 'new_address_state'
        fill_in 'new_address_zip', :with => address.zip
        fill_in 'new_address_phone', :with => address.phone
      end
    end
    
    def return_address_update_should_succeed
      expect(page).to have_flash_message(:notice, 'return_address.updated')
    end
    
    def return_address_creation_should_succeed
      expect(page).to have_flash_message(:notice, 'return_address.created')
    end

    def return_address_blank_error_should_be_for_field(field)
      within "#new_address_new" do
        page.should have_content(I18n.t("activerecord.errors.models.postal_address.attributes.#{field}.blank"))
      end
    end

    def return_address_should_be(address)
      page.should have_content(address.name)
      page.should have_content(address.line1)
    end

    def return_address_modal_should_be_hidden
      retry_expectations do
        expect(page).to have_css("#return_address_change-modal", visible: false)
      end
    end

    def return_address_modal_fields_should_be_empty
      page.all("form#new_address_new input[type=text]").each do |e|
        e.text.should == ''
      end
    end
    
    RSpec::Matchers.define :have_return_address_modal do
      match do |page|
        page.has_css?("#return_address_change-modal", visible: true)
      end
    end
    
    RSpec::Matchers.define :have_return_address_option do |address|
      match do |page|
        page.has_css?("#field-address-id-#{address.id}", visible: true)
      end
    end
    
    RSpec::Matchers.define :have_generate_label_instructions do
      match do |page|
        page.has_css?("[data-role=generate-label]")
      end
    end
    
    RSpec::Matchers.define :have_download_label_instructions do
      match do |page|
        page.has_css?("[data-role=download-label]")
      end
    end
    
    RSpec::Matchers.define :have_label_expired_message do
      match do |page|
        page.has_css?("[data-role=label-expired]")
      end
    end

    RSpec::Matchers.define :have_disabled_generate_label_button do
      match_for_should do |page|
        page.has_css?("[data-action=generate-label].disabled")
      end

      match_for_should_not do |page|
        page.has_no_css?("[data-action=generate-label].disabled")
      end
    end
  end
end

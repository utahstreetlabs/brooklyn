require './acceptance/spec_helper'

feature "Verify seller identity", js: true do
  include_context 'viewing seller identity settings'

  scenario "successfully" do
    fill_in_identity_details
    submit_identity_form
    identity_should_be_validated
  end

  scenario "with incomplete form" do
    submit_identity_form
    form_should_show_errors
  end

  context "without enough information" do
    scenario "after one try" do
      fill_in_identity_details(simulate_more_information_required: true)
      submit_identity_form
      form_should_require_more_information
    end

    scenario "after two tries" do
      fill_in_identity_details(simulate_more_information_required: true)
      submit_identity_form
      submit_identity_form
      form_should_require_more_information_again
    end

    scenario "after three tries" do
      fill_in_identity_details(simulate_more_information_required: true)
      submit_identity_form
      submit_identity_form
      submit_identity_form
      form_should_reject_invalid_identity
    end
  end
end

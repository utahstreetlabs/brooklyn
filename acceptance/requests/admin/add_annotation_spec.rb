require './acceptance/spec_helper'

feature "Add annotations" do
  include_context 'annotations admin'

  let(:user) { FactoryGirl.create(:registered_user) }
  let(:order) { given_order(:confirmed) }

  background do
    given_global_interest
    login_as 'roslin@galactica.mil', superuser: true
  end

  let(:url) { 'http://zombo.com' }

  context "for users" do
    scenario 'succeeds' do
      visit admin_user_path(user.id)
      add_annotation
      should_be_on_user_details_page
      should_have_annotation
    end

    def should_be_on_user_details_page
      current_path.should == admin_user_path(user.id)
    end
  end

  context "for orders", js: true do
    include_context 'order admin'

    scenario 'succeeds for orders, persists across cancellation' do
      visit admin_order_path(order.id)
      add_annotation
      should_be_on_order_details_page
      should_have_annotation

      cancel_order(order)
      should_be_on_order_details_page
      should_have_annotation
    end
  end
end

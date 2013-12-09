require 'spec_helper'
require 'timecop'

describe DashboardController do
  include_context "dashboard layout"

  describe "#show" do
    it_behaves_like "secured against anonymous users" do
      before { get :show }
    end

    context "by a user" do
      before do
        user = act_as_dashboard_user
      end

      it_behaves_like "dashboard layout action" do
        before { get :show }
      end

      it "redirects to for_sale" do
        get :show
        response.should redirect_to(controller: :dashboard, action: :for_sale)
      end
    end
  end

  BUYER_ACTIONS = [:bought]
  BUYER_ACTIONS.each do |action|
    context "##{action}" do
      it_behaves_like "secured against anonymous users" do
        before { get action }
      end

      context "by a user" do
        before { act_as_dashboard_user }

        it_behaves_like "dashboard layout action" do
          before do
            set_listing_expectation(:buyer_id, direction: :asc, includes: :order)
            get action
          end
        end

        it "assigns listings with default ordering" do
          set_listing_expectation(:buyer_id, direction: :asc, includes: :order)
          get action
          assigns(:listings).should be
        end

        it "assigns listings ordered by reverse title" do
          set_listing_expectation(:buyer_id, direction: :desc, order: :title, includes: :order)
          get action, so: 'title', sd: 'desc'
          assigns(:listings).should be
        end
      end
    end
  end

  SELLER_ACTIONS = {
    for_sale: :active,
    inactive: :inactive,
    draft: :incomplete,
    suspended: :suspended,
    sold: :sold,
  }
  SELLER_ACTIONS.each_pair do |action, state|
    context "##{action}" do
      it_behaves_like "secured against anonymous users" do
        before { get action }
      end

      context "by a user" do
        before { act_as_dashboard_user }

        it_behaves_like "dashboard layout action" do
          before do
            set_listing_expectation(:seller_id, direction: :asc, state: state)
            get action
          end
        end

        it "assigns listings with default ordering" do
          set_listing_expectation(:seller_id, direction: :asc, state: state)
          get action
          assigns(:listings).should be
        end

        it "assigns listings ordered by reverse title" do
          set_listing_expectation(:seller_id, direction: :desc, order: :title, state: state)
          get action, sort: 'title', direction: 'desc'
          assigns(:listings).should be
        end
      end
    end
  end

  def set_listing_expectation(id_column, options = {})
    order = options[:order].to_s if options.include?(:order)
    direction = options.fetch(:direction, :asc).to_s
    user_scope = stub('user scope')
    state_scope = stub('state scope')
    if options[:includes]
      listing_scope = stub('listing scope')
      Listing.expects(:includes).with(options.delete(:includes)).returns(listing_scope)
    end
    (listing_scope || Listing).expects(:where).
      #XXX-buyer-id: move back to buyer_id: foo syntax when we drop listing_id buyer_id
      #     and uncomment this line
      #with(id_column => subject.current_user.id).
      returns(user_scope)
    if options.include?(:state)
      user_scope.expects(:with_state).with(options[:state]).returns(state_scope)
      state_scope.expects(:datagrid).with(is_a(Hash), is_a(Hash)).returns([])
    else
      user_scope.expects(:datagrid).with(is_a(Hash), is_a(Hash)).returns([])
    end
  end

  context "login session" do
    # XXX: this test doesn't pass when run by itself.
    it "expires after a period of time" do
      user = act_as_stub_user
      user.expects(:just_registered?).returns(true)
      subject.send(:sign_in, user)
      user.expects(:forget_me!).once
      controller.send(:session).touch!
      Timecop.freeze(Time.now + Brooklyn::Application.config.session.timeout_in + 1.minute) do
        get :show
        response.should be_redirected_to_home_page
        flash[:notice].should =~ /We have logged you out after being idle/
      end
    end
  end
end

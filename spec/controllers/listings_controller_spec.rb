require 'spec_helper'
require 'timecop'

describe ListingsController do
  describe "#new" do
    context "by a new guest user" do
      it "delegates to #create" do
        controller.expects(:create)
        click_new_button
      end
    end

    context "by an existing guest user" do
      before { act_as_guest_user(user: FactoryGirl.create(:guest_user)) }

      it "delegates to #create" do
        controller.expects(:create)
        click_new_button
      end
    end

    context "by a logged-in user" do
      before { act_as(FactoryGirl.create(:registered_user)) }

      it "delegates to #create" do
        controller.expects(:create)
        click_new_button
      end
    end

    def click_new_button
      get :new
    end
  end

  describe "#create" do
    context "by a new guest user" do
      it "creates guest user" do
        click_create_button
        session[:guest_id].should be
      end

      it "assigns listing" do
        click_create_button
        assigns(:listing).should be
      end

      it "redirects to the setup page" do
        click_create_button
        response.should redirect_to(setup_listing_path(assigns(:listing)))
      end
    end

    context "by an existing guest user" do
      let(:user) { FactoryGirl.create(:guest_user) }
      before { act_as_guest_user(user: user) }

      context "without a previously created listing" do
        it "sets listing seller to guest user" do
          click_create_button
          assigns(:listing).seller.should == user
        end

        it "redirects to the setup page" do
          click_create_button
          response.should redirect_to(setup_listing_path(assigns(:listing)))
        end
      end

      context "with a previously created but incomplete listing" do
        let!(:listing) { FactoryGirl.create(:incomplete_listing, seller: user) }

        it "reuses previously created listing" do
          click_create_button
          assigns(:listing).should == listing
        end

        it "sets listing seller to guest user" do
          click_create_button
          assigns(:listing).seller.should == user
        end

        it "redirects to the setup page" do
          click_create_button
          response.should redirect_to(setup_listing_path(listing))
        end
      end

      context "with a previously completed but inactive listing" do
        let!(:listing) { FactoryGirl.create(:inactive_listing, seller: user) }

        it "reuses previously created listing" do
          click_create_button
          assigns(:listing).should == listing
        end

        it "sets listing seller to guest user" do
          click_create_button
          assigns(:listing).seller.should == user
        end

        it "redirects to the listing page" do
          click_create_button
          response.should redirect_to(listing_path(listing))
        end
      end
    end

    context "by a logged-in user" do
      let(:user) { FactoryGirl.create(:registered_user) }
      before { act_as(user) }

      it "sets listing seller to current user" do
        click_create_button
        assigns(:listing).seller.should == user
      end

      it "redirects to the setup page" do
        click_create_button
        response.should redirect_to(setup_listing_path(assigns(:listing)))
      end
    end

    def click_create_button
      post :create
    end
  end

  context "listing actions" do
    let(:listing) do
      stub_listing('foobar', incomplete?: true, dimension_values_id_map: {}, title: Listing::PLACEHOLDER_TITLE,
                   placeholder?: true, 'add_to_collection_slugs=' =>  nil)
    end
    let(:listing_scope) { stub('listing_scope') }

    def setup_with_current_user_as_seller(is_seller)
      ListingsController.expects(:listing_scope).returns(listing_scope)
      listing_scope.expects(:find_by_slug!).with('foobar').returns(listing)
      listing.expects(:sold_by?).returns(is_seller)
    end

    describe "#setup" do
      context "by a guest user" do
        before { act_as_guest_user }

        context "who is the seller" do
          before { setup_with_current_user_as_seller(true) }

          context "when the listing is incomplete" do
            before { listing.expects(:title=).with(nil) }

            it "is successful" do
              visit_setup_page
              response.should render_template(:setup)
            end

            it "assigns listing" do
              visit_setup_page
              assigns[:listing].should == listing
            end
          end

          it "redirects to the listing page if the listing isn't 'incomplete'" do
            listing.expects(:incomplete?).returns(false)
            visit_setup_page
            response.should redirect_to(listing_path(listing))
          end
        end

        context "who is not the seller" do
          before { setup_with_current_user_as_seller(false) }

          it_behaves_like "secured against anonymous users" do
            before { visit_setup_page }
          end
        end
      end

      context "by a logged-in user" do
        before { act_as_stub_user }

        context "who is the seller" do
          before { setup_with_current_user_as_seller(true) }

          context "when the listing is incomplete" do
            before { listing.expects(:title=).with(nil) }

            it "is successful" do
              visit_setup_page
              response.should render_template(:setup)
            end

            it "assigns listing" do
              visit_setup_page
              assigns[:listing].should == listing
            end
          end

          it "redirects to the listing page if the listing isn't 'incomplete'" do
            listing.expects(:incomplete?).returns(false)
            visit_setup_page
            response.should redirect_to(listing_path(listing))
          end
        end

        context "who is not the seller" do
          before { setup_with_current_user_as_seller(false) }

          it_behaves_like "secured against rfbs" do
            before { visit_setup_page }
          end
        end
      end

      def visit_setup_page(params = {})
        p = {:id => listing.to_param}
        get(:setup, p.merge(params))
      end
    end

    describe "#complete" do
      context "by a guest user" do
        let!(:user) { act_as_guest_user }

        context "who is the seller" do
          before do
            setup_with_current_user_as_seller(true)
            listing.expects(:attributes=)
            listing.expects(:reset_slug)
          end

          context "successful completion" do
            before do
              listing.expects(:complete).returns(true)
            end

            it "tracks usage" do
              subject.expects(:track_usage).with(kind_of(Events::CreateListing))
              click_complete_button
            end

            it "redirects to the listing page" do
              click_complete_button
              response.should redirect_to(listing_path(listing))
            end
          end

          it "renders the setup template if the listing is invalid for activation" do
            listing.expects(:restore_slug)
            listing.expects(:complete).returns(false)
            click_complete_button
            response.should render_template(:setup)
          end
        end

        context "who is not the seller" do
          before { setup_with_current_user_as_seller(false) }

          it_behaves_like "secured against anonymous users" do
            before { click_complete_button }
          end
        end
      end

      context "by a logged-in user" do
        context "who is not the seller" do
          before { setup_with_current_user_as_seller(false) }

          it_behaves_like "secured against rfbs" do
            before { click_complete_button }
          end
        end
      end

      def click_complete_button(params = {})
        p = {:id => listing.to_param}
        post(:complete, p.merge(params))
      end
    end

    describe "#draft" do
      context "by a guest user" do
        let!(:user) { act_as_guest_user }

        context "who is the seller" do
          before do
            setup_with_current_user_as_seller(true)
            listing.expects(:attributes=)
          end

          context "successful completion" do
            before do
              listing.expects(:save!)
            end

            it "redirects to the setup page" do
              click_draft_button
              response.should redirect_to(setup_listing_path(listing))
            end
          end
        end

        context "who is not the seller" do
          before { setup_with_current_user_as_seller(false) }

          it_behaves_like "secured against anonymous users" do
            before { click_draft_button }
          end
        end
      end

      context "by a logged-in user" do
        let!(:user) { act_as_stub_user }

        context "who is the seller" do
          before do
            setup_with_current_user_as_seller(true)
            listing.expects(:attributes=)
          end

          context "successful completion" do
            before do
              listing.expects(:save!)
            end

            it "redirects to the setup listing page" do
              click_draft_button
              response.should redirect_to(setup_listing_path(listing))
            end
          end
        end

        context "who is not the seller" do
          before { setup_with_current_user_as_seller(false) }

          it_behaves_like "secured against rfbs" do
            before { click_draft_button }
          end
        end
      end

      def click_draft_button(params = {})
        params = params.merge(:id => listing.to_param)
        if params.delete(:xhr)
          xhr(:post, :draft, params)
        else
          post(:draft, params)
        end
      end
    end

    describe "#activate" do
      context "by the seller" do
        let(:result) { true }
        before do
          user = act_as_stub_user
          setup_with_current_user_as_seller(true)
          listing.expects(:activate).returns(result)
          post :activate, id: listing.to_param
        end

        it "redirects to the listing page" do
          response.should redirect_to(listing_path(listing))
        end

        describe "failure" do
          let(:result) { false }
          it "sets a flash and redirects to the listing page" do
            flash[:error].should =~ /There was an error activating this listing/
            response.should redirect_to(listing_path(listing))
          end
        end
      end
    end
  end

  describe "#show" do
    let(:feed) { stub('feed') }
    let(:like) { stub('like') }
    let(:likes_summary) { stub('likes_summary') }

    def self.expect_service_info_for_guest
      before do
        subject.send(:current_user).expects(:like_for).never
        InternalListing.any_instance.expects(:likes_summary).once.returns(likes_summary)
        ListingFeed.expects(:new).with(listing).once.returns(feed)
        InternalListing.any_instance.expects(:incr_views) if listing.active?
      end
    end

    def self.expect_service_info_for_user
      before do
        subject.send(:current_user).expects(:like_for).with(listing).returns(like)
        InternalListing.any_instance.expects(:likes_summary).once.returns(likes_summary)
        ListingFeed.expects(:new).with(listing).once.returns(feed)
        InternalListing.any_instance.expects(:incr_views) if listing.active?
      end
    end

    context "for an active listing" do
      context "with no order" do
        let(:listing) { FactoryGirl.create(:active_listing, order: nil) }

        context "by a guest" do
          expect_service_info_for_guest

          it "succeeds" do
            controller.expects(:track_usage).with(kind_of(Events::ListingView))
            visit_listing_page(listing)
            response.should be_success
          end
        end

        context "by an rfb" do
          before { act_as_stub_user }
          expect_service_info_for_user

          it "succeeds" do
            visit_listing_page(listing)
            response.should be_success
          end
        end

        context "after session timeout" do
          it "doesn't explode" do
            user = act_as_stub_user
            user.expects(:forget_me!).once
            controller.send(:session).touch!
            Timecop.freeze(Time.now + Brooklyn::Application.config.session.timeout_in + 1.minute) do
              visit_listing_page(listing)
              response.should be_redirected_to_home_page
            end
          end
        end
      end

      context "with a pending order" do
        let(:order) { FactoryGirl.create(:pending_order) }
        let!(:listing) { FactoryGirl.create(:active_listing, :order => order) }

        context "by a guest" do
          expect_service_info_for_guest

          it "succeeds" do
            visit_listing_page(listing)
            response.should be_success
          end
        end

        context "by an rfb" do
          before { act_as_stub_user }
          expect_service_info_for_user

          it "succeeds" do
            visit_listing_page(listing)
            response.should be_success
          end
        end

        context "by the buyer" do
          before { act_as_stub_user user: order.buyer }
          expect_service_info_for_user

          it "succeeds" do
            visit_listing_page(listing)
            response.should be_success
          end
        end

        context "by the seller" do
          before { act_as_stub_user user: listing.seller }
          expect_service_info_for_user

          it "succeeds" do
            visit_listing_page(listing)
            response.should be_success
          end
        end
      end
    end

    context "for a sold listing" do
      let(:listing) { FactoryGirl.create(:sold_listing) }

      [:confirmed, :shipped, :delivered, :complete, :settled].each do |status|
        context "with a #{status} order" do
          let!(:order) { FactoryGirl.create("#{status}_order".to_sym, :listing => listing) }

          context "by a guest" do
            expect_service_info_for_guest

            it "succeeds" do
              visit_listing_page(listing)
              response.should be_success
            end
          end

          context "by an rfb" do
            before { act_as_stub_user }
            expect_service_info_for_user

            it "succeeds" do
              visit_listing_page(listing)
              response.should be_success
            end
          end

          context "by the buyer" do
            before { act_as_stub_user user: order.buyer }
            expect_service_info_for_user

            it "succeeds" do
              visit_listing_page(listing)
              response.should be_success
            end
          end

          context "by the seller" do
            before { act_as_stub_user user: listing.seller }
            expect_service_info_for_user

            it "succeeds" do
              visit_listing_page(listing)
              response.should be_success
            end

            it "has a printable view" do
              get :invoice, {:id => listing.to_param}
              response.should be_success
            end

          end
        end
      end
    end

    context "for a listing in any other state" do
      let(:listing) { FactoryGirl.create(:suspended_listing) }

      it_behaves_like "secured against anonymous users" do
        before { visit_listing_page(listing) }
      end

      it_behaves_like "secured against rfbs" do
        before { visit_listing_page(listing) }
      end

      context "by an admin" do
        before { act_as_stub_user admin: true }
        expect_service_info_for_user

        it "succeeds" do
          visit_listing_page(listing)
          response.should be_success
        end
      end
    end

    def visit_listing_page(listing, params = {})
      p = {:id => listing.to_param}
      get(:show, p.merge(params))
    end
  end

  describe "#like" do
    let(:listing) { FactoryGirl.create(:active_listing) }

    it_behaves_like "secured against anonymous users" do
      before { click_like_link }
    end

    context "by a user" do
      let(:user) { act_as_stub_user }
      let(:like1) { stub('like1', user_id: 123) }
      let(:like2) { stub('like2', user_id: 456) }
      let(:likes) { [like1, like2] }
      let(:likes_summary) { stub('likes_summary', count: likes.size, liker_ids: []) }
      let(:new_like) { stub('new_like', tombstone: false) }

      context "when recording a like" do
        it "records successfully" do
          user.expects(:like).with(listing, is_a(Hash)).returns(new_like)
          click_like_link
          response.should redirect_to(listing_path(listing))
        end
      end

      context "when recording a like remotely" do
        it "records successfully" do
          user.expects(:like).with(listing, is_a(Hash)).returns(new_like)
          InternalListing.any_instance.expects(:likes_summary).returns(likes_summary)
          subject.stubs(:prompt_share?).with(:listing_liked, anything).returns(true)
          click_like_link(true)
          response.should be_jsend_success
          response.jsend_data['button'].should be
          response.jsend_data['love_box'].should be
        end
      end
    end

    def click_like_link(remote = false)
      params = {:id => listing.slug}
      if remote
        xhr :put, :like, {:format => :json}.merge(params)
      else
        put :like, params
      end
    end
  end

  describe "#unlike" do
    let(:listing) { FactoryGirl.create(:active_listing) }
    let(:likes) { [] }
    let(:likes_summary) { stub('likes_summary', count: likes.size, liker_ids: []) }

    it_behaves_like "secured against anonymous users" do
      before { click_unlike_link }
    end

    context "by a user" do
      let(:user) { act_as_stub_user }

      context "when removing a like" do
        it "removes the like successfully" do
          user.expects(:unlike).with(listing)
          click_unlike_link
          response.should redirect_to(listing_path(listing))
        end
      end

      context "when removing the like remotely" do
        it "removes the like successfully" do
          user.expects(:unlike).with(listing)
          InternalListing.any_instance.expects(:likes_summary).returns(likes_summary)
          click_unlike_link(true)
          response.should be_jsend_success
          response.jsend_data['button'].should be
          response.jsend_data['love_box'].should be
        end
      end
    end

    def click_unlike_link(remote = false)
      params = {:id => listing.slug}
      if remote
        xhr :put, :unlike, {:format => :json}.merge(params)
      else
        put :unlike, params
      end
    end
  end

  describe "#flag" do
    let(:listing) { FactoryGirl.create(:active_listing) }

    it_behaves_like "secured against anonymous users" do
      before { click_flag_link }
    end

    context "by a user" do
      let(:user) { act_as_stub_user }

      before do
        InternalListing.any_instance.expects(:flag).with(user).once
        user.stubs(:flagged?).returns(true)
      end

      context "as html" do
        it "tracks usage" do
          subject.expects(:track_usage).with(:flag_listing)
          click_flag_link
        end

        it "redirects to the listing page" do
          click_flag_link
          response.should redirect_to(listing_path(listing))
        end

        it "sets a flash notice" do
          click_flag_link
          flash[:notice].should have_flash_message('listings.flagged')
        end
      end

      context "as js" do
        it "tracks usage" do
          subject.expects(:track_usage).with(:flag_listing)
          click_flag_link(true)
        end

        it "renders jsend success" do
          click_flag_link(true)
          response.should be_jsend_success
        end

        it "return refresh html" do
          click_flag_link(true)
          response.jsend_data['refresh'].should be
        end
      end
    end

    def click_flag_link(remote = false)
      params = {:id => listing.slug}
      if remote
        xhr :put, :flag, {:format => :json}.merge(params)
      else
        put :flag, params
      end
    end
  end

  describe "#ship" do
    let(:listing) { FactoryGirl.create(:sold_listing) }
    let!(:order) { FactoryGirl.create(:confirmed_order, listing: listing) }

    let(:tracking_number) { '1Z12345E0205271688' }

    it "requires a listing" do
      submit_ship_form("not-a-listing")
      response.should_not be_success
    end

    it_behaves_like "secured against anonymous users" do
      before { submit_ship_form }
    end

    it_behaves_like "secured against rfbs" do
      before { submit_ship_form }
    end

    context "by the buyer" do
      before { act_as_stub_user user: order.buyer }

      it "is not authorized to ship" do
        submit_ship_form
        response.should be_redirected_to_home_page
      end
    end

    context "by the seller" do
      before { act_as_stub_user user: listing.seller }

      context "when the order is shippable" do
        context "without valid tracking number" do
          let(:tracking_number) { '123' }
          let(:feed) { stub('feed') }
          let(:like) { stub('like') }
          let(:likes_summary) { stub('likes_summary') }

          before do
            subject.send(:current_user).expects(:like_for).with(listing).returns(like)
            InternalListing.any_instance.expects(:likes_summary).returns(likes_summary)
            ListingFeed.expects(:new).with(listing).once.returns(feed)
          end

          it "fails" do
            submit_ship_form
            response.should_not be_redirected_to_listing
          end

          it "assigns photos" do
            submit_ship_form
            assigns(:photos).should be
          end

          it "assigns feed" do
            submit_ship_form
            assigns(:feed).should be
          end

          it "assigns like" do
            submit_ship_form
            assigns(:like).should be
          end

          it "assigns like summary" do
            submit_ship_form
            assigns(:likes_summary).should be
          end

          it "does not assign connection" do
            submit_ship_form
            assigns(:connection).should be_nil
          end
        end

        context "with a valid tracking number" do
          it "succeeds" do
            submit_ship_form
            response.should be_redirected_to_listing
          end
        end
      end

      context "when the order is not shippable" do
        let!(:order) { FactoryGirl.create(:shipped_order, listing: listing) }

        it "fails with an error" do
          submit_ship_form
          response.should be_redirected_to_listing
          flash[:alert].should have_flash_message('listings.already_shipped')
        end
      end
    end

    def submit_ship_form(slug = nil)
      post :ship, id: (slug || listing.slug), shipment: {carrier_name: 'ups', tracking_number: tracking_number}
    end
  end

  describe '#deliver' do
    let!(:order) { FactoryGirl.create(:shipped_order) }
    let!(:listing) { order.listing }

    it "requires a listing" do
      submit_deliver_form("not-a-listing")
      response.should_not be_success
    end

    it_behaves_like "secured against anonymous users" do
      before { submit_deliver_form }
    end

    it_behaves_like "secured against rfbs" do
      before { submit_deliver_form }
    end

    context "by the seller" do
      before { act_as_stub_user user: listing.seller }

      it "is not authorized to deliver" do
        submit_deliver_form
        response.should be_redirected_to_home_page
      end
    end

    context "by the buyer" do
      before { act_as_stub_user user: order.buyer }

      it "delivers the order" do
        submit_deliver_form
        order.reload
        order.should be_delivered
        response.should be_redirected_to_listing
      end
    end

    def submit_deliver_form(slug = nil)
      post :deliver, id: (slug || listing.slug)
    end
  end

  describe '#not_delivered' do
    let!(:order) { FactoryGirl.create(:shipped_order) }
    let!(:listing) { order.listing }

    it "requires a listing" do
      submit_not_delivered_form("not-a-listing")
      response.should_not be_success
    end

    it_behaves_like "secured against anonymous users" do
      before { submit_not_delivered_form }
    end

    it_behaves_like "secured against rfbs" do
      before { submit_not_delivered_form }
    end

    context "by the seller" do
      before { act_as_stub_user user: listing.seller }

      it "is not authorized" do
        submit_not_delivered_form
        response.should be_redirected_to_home_page
      end
    end

    context "by the buyer" do
      before { act_as_stub_user user: order.buyer }

      it "delivers the order" do
        Order.any_instance.expects(:report_non_delivery!)
        submit_not_delivered_form
        flash[:notice].should be
        response.should be_redirected_to_listing
      end
    end

    def submit_not_delivered_form(slug = nil)
      post :not_delivered, id: (slug || listing.slug)
    end
  end

  describe "#finalize" do
    let(:listing) { FactoryGirl.create(:sold_listing) }
    let!(:order) { FactoryGirl.create(:delivered_order, listing: listing) }
    before { Order.any_instance.stubs(:skip_credit).returns(true) }

    it "requires a listing" do
      submit_finalize_form("not-a-listing")
      response.should_not be_success
    end

    it_behaves_like "secured against anonymous users" do
      before { submit_finalize_form }
    end

    it_behaves_like "secured against rfbs" do
      before { submit_finalize_form }
    end

    context "by the seller" do
      before do
        act_as_stub_user user: order.buyer
      end

      it "succeeds" do
        submit_finalize_form
        response.should be_redirected_to_listing
      end
    end

    context "by the buyer" do
      before do
        act_as_stub_user user: order.buyer
      end

      it "succeeds" do
        submit_finalize_form
        response.should be_redirected_to_listing
      end
    end

    def submit_finalize_form(slug = nil)
      post :finalize, :id => (slug || listing.slug)
    end
  end

  describe "#destroy" do
    let (:listing) { FactoryGirl.create(:active_listing) }

    it_behaves_like "secured against anonymous users" do
      before { click_cancel_listing }
    end

    it_behaves_like "secured against rfbs" do
      before { click_cancel_listing }
    end

    it "is secured against the buyer" do
      act_as_stub_user user: listing.buyer
      click_cancel_listing
      response.should be_redirected_to_home_page
    end

    context "by the seller" do
      before do
        act_as_stub_user user: listing.seller
        IndexListingObserver.any_instance.expects(:after_cancel)
      end

      it "redirects without errors if listing isn't cancellable" do
        listing.cancel!
        subject.expects(:handle_state_transition_error).never
        click_cancel_listing
        response.should redirect_to(listing_path(listing))
      end

      it "cancels the listing" do
        click_cancel_listing
        listing.reload.should be_cancelled
      end

      it "tracks usage" do
        subject.expects(:track_usage).with(kind_of(Events::CancelListing))
        click_cancel_listing
      end

      it "sets a flash message" do
        click_cancel_listing
        flash[:notice].should have_flash_message('listings.canceled')
      end

      it "redirects to the dashboard" do
        click_cancel_listing
        response.should be_redirected_to_dashboard
      end
    end

    def click_cancel_listing
      delete :destroy, id: listing.slug
    end
  end

  describe "#change_shipping" do
    let (:order) { FactoryGirl.create(:confirmed_order) }
    let (:address) { FactoryGirl.create(:shipping_address, user: order.buyer) }

    it_behaves_like "secured against anonymous users" do
      before { click_change_shipping }
    end

    it_behaves_like "secured against rfbs" do
      before { click_change_shipping }
    end

    it "is secured against the seller" do
      act_as(order.listing.seller)
      click_change_shipping
      response.should be_redirected_to_home_page
    end

    context "as the buyer" do
      before do
        act_as_stub_user(user: order.buyer)
      end

      it "changes the shipping address associated with the order" do
        click_change_shipping
        response.should redirect_to(listing_path(order.listing))
        flash[:notice].should have_flash_message('listings.shipping_address_changed')
        order.reload
        addresses_should_match(order.shipping_address, address)
      end

      it "doesn't change shipping address if the buyer has waited too long after confirmation" do
        Timecop.freeze(Time.zone.now + Order.shipping_address_change_window + 10.minutes) do
          click_change_shipping
          address_change_fails
        end
      end

      context "of a shipped order" do
        let (:order) { FactoryGirl.create(:shipped_order) }

        it "doesn't change the shipping address" do
          click_change_shipping
          address_change_fails
        end
      end
    end

    def address_change_fails
      response.should redirect_to(listing_path(order.listing))
      flash[:notice].should have_flash_message('listings.shipping_address_unchangable')
      order.reload
      order.shipping_address.should_not == address
    end

    def click_change_shipping
      post :change_shipping, id: order.listing.slug, address_id: address.id
    end
  end

  describe "#share" do
    let(:user) { act_as_stub_user }
    let(:seller) { stub_user("Charles Mulligan's Steakhouse") }
    let(:listing) { stub_listing('Steak Knives (24)', seller: seller) }

    before do
      scope = mock('listing-scope')
      Listing.expects(:scoped).returns(scope)
      scope.expects(:find_by_slug!).with(listing.slug).returns(listing)
    end

    context "for a shareable network" do
      before do
        ListingPhoto.expects(:find).with(listing.photos.first.id.to_s).returns(listing.photos.first)
      end

      Network.shareable.each do |network|
        it "shares a listing to #{network}" do
          seller.person.stubs(:for_network).returns(nil)
          user.person.class.stubs(:sharing_options!).returns({text: "foo"})
          listing.expects(:incr_shares).with(user, network)
          Brooklyn::UsageTracker.expects(:async_track).with(:"share_listing_#{network}", is_a(Hash))
          click_share_link(network)
          response.should be_redirect
          response.headers['Location'].should =~ /#{network}/
        end
      end
    end

    context "for an unshareable network" do
      it "returns not found" do
        network = :friendster
        listing.expects(:incr_shares).never
        click_share_link(network)
        response.should render_template('errors/not_found')
      end
    end

    def click_share_link(network)
      get :share, id: listing.slug, network: network, photo_id: listing.photos.first.id
    end
  end

  def be_redirected_to_listing
    redirect_to(listing_path(listing))
  end
end

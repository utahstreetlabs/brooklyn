require 'spec_helper'

describe Listings::ShippingLabelController do
  let(:scope) { mock('listing-scope') }
  let(:listing) { stub_listing 'Ninja star' }

  before do
    Listing.stubs(:scoped).returns(scope)
    scope.stubs(:find_by_slug!).with(listing.slug).returns(listing)
  end

  describe '.create' do
    it_behaves_like 'secured against anonymous users' do
      before { do_create }
    end

    it_behaves_like 'secured against rfbs' do
      let(:order) { stub_order(listing, status: :confirmed) }
      before do
        listing.stubs(:order).returns(order)
        do_create
      end
    end

    context 'for the seller' do
      before { act_as_stub_user user: listing.seller }

      it 'requires a listing' do
        slug = 'foobar'
        scope.stubs(:find_by_slug!).with(slug).raises(ActiveRecord::RecordNotFound)
        do_create(listing_id: slug)
        response.status.should == 404
      end

      it 'requires a confirmed order' do
        listing.stubs(:order).returns(nil)
        do_create
        response.should be_redirected_to_home_page
      end

      context 'with a confirmed order' do
        let(:order) { stub_order(listing, status: :confirmed) }
        before { listing.stubs(:order).returns(order) }

        context 'when the order does not have a shipping label' do
          before { order.stubs(:shipping_label).returns(nil) }

          it 'creates a remote shipping label' do
            order.expects(:create_prepaid_shipment_and_label!)
            do_create
            response.should be_redirected_to_listing_page
          end

          it 'handles an invalid to address error creating a shipping label' do
            order.expects(:create_prepaid_shipment_and_label!).
              raises(Brooklyn::ShippingLabels::InvalidToAddress.new("Oh noes!"))
            do_create
            response.should be_redirected_to_listing_page
            # the alert is kind of complex to create, so we'll just test that it contains the # buyer's email address
            # (which is enough to distinguish this case from the generic error case)
            flash[:alert].should match(/#{order.buyer.email}/)
          end

          it 'handles a generic error creating a shipping label' do
            order.expects(:create_prepaid_shipment_and_label!).
              raises(Brooklyn::ShippingLabels::ShippingLabelException.new("Oh noes!"))
            do_create
            response.should be_redirected_to_listing_page
            flash[:alert].should have_flash_message('listings.shipping_label.error_creating')
          end
        end

        context 'when the order has a shipping label' do
          before { order.stubs(:shipping_label).returns(mock('shipping_label')) }

          it 'does nothing' do
            order.expects(:create_prepaid_shipment_and_label!).never
            do_create
            response.should be_redirected_to_listing_page
          end
        end
      end
    end

    def do_create(params = {})
      params.reverse_merge!(listing_id: listing.slug)
      post :create, params
    end
  end

  describe '.show' do
    it_behaves_like 'secured against anonymous users' do
      before { do_show }
    end

    it_behaves_like 'secured against rfbs' do
      let(:order) { stub_order(listing, status: :confirmed) }
      before do
        listing.stubs(:order).returns(order)
        do_show
      end
    end

    context 'for the seller' do
      before { act_as_stub_user user: listing.seller }

      it 'requires a listing' do
        slug = 'foobar'
        scope.stubs(:find_by_slug!).with(slug).raises(ActiveRecord::RecordNotFound)
        do_show(listing_id: slug)
        response.status.should == 404
      end

      it 'requires a confirmed order' do
        listing.stubs(:order).returns(nil)
        do_show
        response.should be_redirected_to_home_page
      end

      context 'with a confirmed order' do
        let(:order) { stub_order(listing, status: :confirmed) }
        before { listing.stubs(:order).returns(order) }

        context 'when the order does not have a shipping label' do
          before { order.stubs(:shipping_label).returns(nil) }

          it 'does nothing' do
            do_show
            controller.expects(:send_file).never
            response.should be_redirected_to_listing_page
          end
        end

        context 'when the order has a shipping label' do
          let(:label) { stub('label', suggested_filename: 'label.pdf', media_type: 'application/pdf') }
          before { order.stubs(:shipping_label).returns(label) }

          it 'gets and sends the label file' do
            file = stub('file', path: '/foo/bar')
            label.stubs(:to_file).returns(file)
            # stub send_file so that we don't have to provide a real file. since this causes the controller to call
            # render, stub that too.
            controller.expects(:send_file).with(file.path, filename: label.suggested_filename, type: label.media_type)
            controller.stubs(:render)
            do_show
            response.status.should == 200
          end

          it 'handles an error getting the label file' do
            label.stubs(:to_file).raises(Brooklyn::ShippingLabels::ShippingLabelException.new("Oh noes!"))
            controller.expects(:send_file).never
            do_show
            response.should be_redirected_to_listing_page
            flash[:alert].should have_flash_message('listings.shipping_label.error_downloading')
          end
        end
      end
    end

    def do_show(params = {})
      params.reverse_merge!(listing_id: listing.slug)
      get :show, params
    end
  end

  def be_redirected_to_listing_page
    redirect_to(listing_path(listing))
  end
end

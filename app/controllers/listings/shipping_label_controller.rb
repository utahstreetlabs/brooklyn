class Listings::ShippingLabelController < ApplicationController
  include Controllers::ListingScoped

  customize_action_event variables: [:listing]
  set_flash_scope 'listings.shipping_label'
  set_listing
  require_listing
  require_order status: :confirmed
  require_seller

  before_filter do
    @label = @listing.order.shipping_label
  end

  def create
    unless @label
      begin
        @listing.order.create_prepaid_shipment_and_label!
      rescue Brooklyn::ShippingLabels::InvalidToAddress => e
        # user-level error that the user can resolve
        logger.warn("Invalid to address for shipping label for listing #{@listing.id}: #{e}")
        email_buyer_link = view_context.mail_to(@listing.order.buyer.email, localized_flash_message(:email_buyer_link))
        set_flash_message(:alert, :invalid_shipping_address_html, email_buyer_link: email_buyer_link)
      rescue Brooklyn::ShippingLabels::ShippingLabelException => e
        # service failures that we can't do anything about
        logger.warn("Generating shipping label for listing #{@listing.id} failed: #{e}")
        set_flash_message(:alert, :error_creating)
      # all other exceptions are handled by the default error handler
      end
    end
    redirect_to(listing_path(@listing))
  end

  def show
    if @label
      begin
        # send as attachment so that the doc is saved rather than rendered in the browser
        return send_file(@label.to_file.path, filename: @label.suggested_filename, type: @label.media_type)
      rescue Brooklyn::ShippingLabels::ShippingLabelException => e
        self.class.handle_error("Download shipping label", e, listing_id: @listing.id)
        set_flash_message(:alert, :error_downloading)
      # all other exceptions are handled by the default error handler
      end
    else
      logger.warn("No shipping label to download for order #{@listing.order.id}")
    end
    redirect_to(listing_path(@listing))
  end
end

class Admin::Orders::ShipmentsController < ApplicationController
  set_flash_scope 'admin.orders.shipments'
  load_resource :order, class: 'Order'
  respond_to :json

  def update
    # because AR does not have an identity map, @order and @order.shipment.order are not the same object. after
    # updating @order.shipment, use the shipment's child order rather than its parent order so that the changes to
    # the shipment are reflected in the rendered partial.
    shipment = @order.shipment
    authorize!(:update, shipment)
    # allow the admin to enter whatever wacky tracking number the buyer got (or thinks they got). usually the admin
    # has to update the tracking number when the buyer used an unsupported carrier or somehow has a tracking number
    # that we don't think is valid. to support this use case, we simply don't validate the tracking number's syntax
    # when the admin updates it.
    shipment.suppress_tracking_number_syntax_validation if params[:skip_tracking_validation]
    if shipment.update_attributes(shipment_params)
      data = {
        alert: view_context.admin_notice(:success, localized_flash_message(:updated)),
        refresh: render_to_string(partial: '/admin/orders/order_info.html', locals: {order: shipment.order})
      }
      render_jsend(success: data)
    else
      data = {modal: render_to_string(partial: 'update_modal', locals: {shipment: shipment})}
      data[:message] = localized_flash_message(:error_tracking) if shipment.errors[:tracking_number].present?
      render_jsend(fail: data)
    end
  end

  protected
    def shipment_params
      params[:shipment].slice(:carrier_name, :tracking_number)
    end
end

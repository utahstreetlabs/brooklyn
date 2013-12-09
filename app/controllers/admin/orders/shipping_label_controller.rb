class Admin::Orders::ShippingLabelController < ApplicationController
  set_flash_scope 'admin.orders.shipping_label'
  load_resource :order, class: 'Order'

  def show
    if @order.shipping_label
      authorize!(:show, @order.shipping_label)
      send_file(@order.shipping_label.to_file.path, filename: @order.shipping_label.suggested_filename,
                type: @order.shipping_label.media_type, disposition: 'inline')
    else
      redirect_to(admin_order_path(@order))
    end
  end
end

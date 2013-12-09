jQuery ->
  $shipping = $('#listing_shipping')
  $freeShipping = $('#listing_free_shipping')

  $shipping.on 'change', () ->
    shippingPrice = $.trim($shipping.val())
    if shippingPrice == '' or parseFloat(shippingPrice) == 0
      $freeShipping.attr('checked', 'checked')
    else
      $freeShipping.removeAttr('checked')

  $freeShipping.on 'change', () ->
    if $freeShipping.is(':checked')
      $shipping.val('0.00')
      $shipping.trigger('change')

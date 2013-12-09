jQuery ->
  initOrderForm = ($container) ->
    $.remoteForm.initRemoteForm($container)
    $('form', $container).on 'jsend:success', (event, data) ->
      $("[data-listing=#{data.listingId}]").replaceWith data.listing
      initOrderForm $("[data-listing=#{data.listingId}]")

  _.each $("[data-role='dashboard-order-form']"), (element) -> initOrderForm $(element)

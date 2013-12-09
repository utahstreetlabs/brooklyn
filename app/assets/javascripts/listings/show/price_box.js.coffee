jQuery ->
  # ensure the buy button is disabled once it's been clicked
  $('[data-action=buy]').on 'click', () ->
    $buyButton = $(this)
    $buyButton.addClass('disabled') unless $(this).data('role') is 'external-listing-link'
    $buyButton.on 'click', () -> false

  $('#make-an-offer-modal').on 'shown', () ->
    $modal = $(this)
    copious.track('make_offer click', offerer: $modal.data('offerer'), listing: $modal.data('listing'), source: this)

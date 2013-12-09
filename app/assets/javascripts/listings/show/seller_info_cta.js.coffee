jQuery ->
  # pop up the seller info cta modal when the active listing cta modal is closed
  $('#active_listing_cta-modal').on 'hidden', () -> $('#seller_info_cta-modal').modal('show')

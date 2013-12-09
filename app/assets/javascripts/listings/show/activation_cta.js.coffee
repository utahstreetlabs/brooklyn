jQuery ->
  $activatedCta = $('#active_listing_cta-modal')

  # show the activation cta modal explicitly since it's not triggered by a toggle control
  $activatedCta.modal('show')

  # pop up a window for social network share forms
  $activatedCta.on 'click', '.share-listing a', () ->
    share = window.open(this.href, 'share-listing', 'height=450,width=550');
    share.focus() if window.focus
    false

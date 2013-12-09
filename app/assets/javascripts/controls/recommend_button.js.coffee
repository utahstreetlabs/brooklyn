jQuery ->
  $(document).on 'click', '[data-action=recommend-cta]', (e) ->
    $button = $(this)
    new Copious.InviteModal($($button.data('target')), source: copious.source($button))

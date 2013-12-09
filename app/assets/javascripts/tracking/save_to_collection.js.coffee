jQuery ->
  $(document).on 'click', '[data-action=save-to-collection-cta]', (e) ->
    $button = $(this)
    copious.track('save_modal view', source: this)

  $(document).on 'shown', '[data-role=want-modal]', ->
    copious.track('want_modal view', source: this)

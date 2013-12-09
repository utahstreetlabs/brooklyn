jQuery ->
  $(document).on 'show', '#logging_in-modal', (e) ->
    $button = $(this)
    mixpanel.track('login_modal view', {page_source: $button.data('page-source')})

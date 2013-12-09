jQuery ->
  # a shim to get autofocus working in ie
  $(document).on 'shown', '.modal', (e) ->
    modal = e.currentTarget
    $('[autofocus]', modal).autofocus()

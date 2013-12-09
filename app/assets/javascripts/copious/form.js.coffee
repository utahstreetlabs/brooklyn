jQuery ->
  window.submitOnEnter = (element, event) ->
    if (event.which == 13)
      event.preventDefault()
      $(element).closest('form').submit()

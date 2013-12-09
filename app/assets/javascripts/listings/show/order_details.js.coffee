jQuery ->
  $(document).on 'click', '[data-role=change-shipping]', (e) ->
    e.preventDefault()
    $($(this).attr('href')).toggle('slow')

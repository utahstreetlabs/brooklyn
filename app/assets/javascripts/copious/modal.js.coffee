jQuery ->
  # auto-hide the modal after 5 seconds
  $(document).on 'shown', '.modal[data-auto-hide]', ->
    setTimeout((=> $(this).modal('hide')), 5000)

  # apply dotdotdot
  $(document).on 'shown', '.modal', ->
    $(this).find('.ellipsis').dotdotdot(wrap: 'letter')
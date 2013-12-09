class RemoveCard
  constructor: (@element, options) ->
    @removeUI = $('[data-role=remove-ui]', @element)

  showUI: () => @removeUI.show()
  hideUI: () => @removeUI.hide()

jQuery ->
  # plugin definition
  $.fn.removeCard = (option) ->
    $(this).each () ->
      $element = $(this)
      cb = $element.data('remove-button')
      unless cb
        options = typeof option == 'object' && option
        $element.data('remove-button', (cb = new RemoveCard($element, options)))
      cb[option]() if (typeof option == 'string')

  # data api
  $(document).on 'click', '[data-action=remove]', ->
    $(this).closest('[data-card=product]').removeCard('showUI')

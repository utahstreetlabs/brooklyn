# Requires copious/remote_form and copious/form to also be loaded
class FlipButton
  constructor: (@flipElement, options) ->
    @options = $.extend({}, this.defaultOptions(), options)
    @front = true
    @flipElement.on 'webkitTransitionEnd mozTransitionEnd transitionend', () =>
      if this.isBacksideDisplayed()
        @flipElement.trigger('flipButton:flippedToBack')
      else
        @flipElement.trigger('flipButton:flippedToFront')

  defaultOptions: () => {}

  setFront: () => @front = true
  setBack: () => @front = false
  isBacksideDisplayed: () => @front is false

  flipToBack: () =>
    @flipElement.trigger('flipButton:flipToBack')
    this.setBack()
    @flipElement.addClass('flipped')
  flipToFront: () =>
    @flipElement.trigger('flipButton:flipToFront')
    this.setFront()
    @flipElement.removeClass('flipped')
  flip: () =>
    if (this.isBacksideDisplayed())
      this.flipToFront()
    else
      this.flipToBack()

jQuery ->
  # plugin definition
  $.fn.flipButton = (option) ->
    $(this).each () ->
      $card = $(this).closest('[data-flip=card]')
      cb = $card.data('flipper-button')
      unless cb
        options = typeof option == 'object' && option
        $card.data('flipper-button', (cb = new FlipButton($card, options)))
      cb[option]() if (typeof option == 'string')

  $.fn.flipButton.defaults = {}

  # data api
  $('body').on 'click', '[data-flip=button]', () ->
    $(this).flipButton('flip')


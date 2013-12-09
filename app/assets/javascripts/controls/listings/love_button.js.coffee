#= require copious/jsend
#= require copious/tracking

class LoveButtonContainer
  constructor: (@element, options) ->
    @options = $.extend({}, $.fn.loveButton.defaults, options)
    @bound = false

    this.enable()

  # Binds the container to components within it. The container may be rebound without side effect, which is useful
  # if the dom within the container element changes after initial binding.
  bind: () =>
    # if the container is already bound, this rebinds it
    @buttonElement = @element.find('[data-toggle=love]')
    @contentElement = @element.find('[data-role=love-button-content]')
    @url = @buttonElement.data('target')
    @method = @buttonElement.data('method')
    @bound = true

  # Performs an ajax request to either create or destroy a like. Binds the container if it is not already bound.
  toggle: () =>
    this.bind() unless @bound

    options = {
      beforeSend: ( =>
        # _speculativelyUpdate changes enabled state, so save it before doing that
        allow = this.isEnabled()
        this._speculativelyUpdate() if allow
        allow
      )
    }
    query = {
      source: copious.source(@buttonElement),
      page_source: copious.pageSource(),
    }
    $.jsend.ajax(@url, query, @method, options).
      then((data) =>
        this.enable()
        $(document).trigger "loveButton:replaced", [data.listingId, data.button] if data.button?
        $(document).trigger "listingStats:replaced", [data.listingId, data.stats] if data.stats?
        @element.trigger("loveButton:loved", [data])
      ).
      fail((status, data) =>
        this._revertUpdate()
      )

  # update the button state and display in advance of the remote action completing, in order to provide the most
  # responsive user experience
  _speculativelyUpdate: () =>
    this.disable()
    if @buttonElement.data('action') is 'love'
      @contentElement.addClass('disabled')
    else
      @contentElement.removeClass('disabled')

  # undo the state and display changes made by speculatively updating in case the remote action fails
  _revertUpdate: () =>
    this.enable()
    @contentElement.toggleClass('disabled')

  enable: () => @enabled = true

  disable: () => @enabled = false

  isEnabled: () => @enabled is true

jQuery ->
  # plugin definition
  $.fn.loveButton = (option) ->
    $(this).each () ->
      $element = $(this)
      lb = $element.data('love-button')
      unless lb
        options = typeof option == 'object' && option
        $element.data('love-button', (lb = new LoveButtonContainer($element, options)))
      lb[option]() if (typeof option == 'string')

  $.fn.loveButton.defaults = {}

  # data api
  $(document).on 'click', '[data-toggle=love]', (e) ->
    $(this).parent().loveButton('toggle')

  $(document).on 'loveButton:replaced', (e, listingId, html) ->
    # first replace all the button html, then rebind each button to the new dom
    $(document).find("[data-listing=#{listingId}] [data-toggle=love]").replaceWith(html)
    $(document).find("[data-listing=#{listingId}] [data-toggle=love]").parent().loveButton('bind')

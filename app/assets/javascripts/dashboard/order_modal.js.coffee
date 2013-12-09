class DashOrderModal
  constructor: (@element, options) ->
    @options = $.extend({}, $.fn.dashOrderModal.defaults, options)

    @element.on 'jsend:success', (event, data) =>
      # XXX: may already have been attached in a handler in remotelink or another library
      copious.flash.notice(data.message) if data.message

      # must happen before listing is replaced since @element gets nuked when that happens
      @element.modal('hide')

      # replace the existing listing block with the one provided in the response. destroys @element, so after replacing,
      # we have to initialize any statically initialized components in the new dom elements.
      if data.listing
        listingSelector = "[data-listing='#{data.listingId}']"
        $(listingSelector).replaceWith(data.listing)
        $listing = $(listingSelector)
        # XXX: initialize remote links on click!
        $("[data-link=multi-remote]", $listing).each -> $.remoteLink.initRemoteLink(this)

      # if a followup modal is provided in the response, create a new modal that is completely separate from the
      # existing one and then remove it from the dom once it has been closed.
      if data.modal
        $followupModal = $(data.modal)
        $followupModal.on 'hide', () -> $followupModal.remove()
        $followupModal.modal('show')

jQuery ->
  # plugin definition
  $.fn.dashOrderModal = (option) ->
    $(this).each () ->
      $element = $(this)
      dom = $element.data('dash-order-modal')
      unless dom
        options = typeof option == 'object' && option
        $element.data('dash-order-modal', (dom = new DashOrderModal($element, options)))
      dom[option]() if (typeof option == 'string')

  $.fn.dashOrderModal.defaults = {
    # no options supported yet
  }

  # data api
  $(document).on 'show', '.modal[data-role=dash-order-modal]', ->
    $(this).dashOrderModal()

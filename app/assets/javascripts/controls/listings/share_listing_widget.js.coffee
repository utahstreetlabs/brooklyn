#= require jquery_ujs

# This widget contains controls for sharing a listing to external sites.
class ShareListingWidget
  constructor: (@element, options) ->
    options = $.extend({}, $.fn.shareListingWidget.defaults, options)

    @height = options.height
    @width = options.width

  share: =>
    # don't cache the url in an instance variable as it may have been changed since the widget was created
    w = window.open(@element.attr('href'), 'share-listing', "height=#{@height},width=#{@width}")
    w.focus() if window.focus

jQuery ->
  # plugin api
  $.fn.shareListingWidget = (option) ->
    $(this).each ->
      $element = $(this)
      data = $element.data('shareListingWidget')
      unless data?
        $element.data('shareListingWidget', (data = new ShareListingWidget($element)))
      if typeof option is 'string'
        data[option].call($element)

  $.fn.shareListingWidget.defaults = {
    height: 450,
    width: 550
  }

  # data api
  $(document).on 'click', '[data-role=share]', (e) ->
    $(this).shareListingWidget('share')
    $.rails.stopEverything(e)

  $(document).on 'photo:selected', (e, $photo) ->
    photoId = $photo.data('photo')
    $('[data-role=share]').each (i, widget) ->
      $widget = $(widget)
      $widget.attr('href', $widget.attr('href').replace(/\/\d+$/, "/#{photoId}"))

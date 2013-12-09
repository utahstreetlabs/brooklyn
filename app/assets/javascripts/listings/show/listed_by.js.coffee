# Requires the controls/excerpt and copious/follow JS libraries.
class ListedBy
  constructor: (@element, options) ->
    @options = $.extend({}, $.fn.listedBy.defaults, options)
    @excerpt = $('[data-role=bio]', @element).excerpt(@options)

jQuery ->
  # plugin definition
  $.fn.listedBy = (option) ->
    $(this).each () ->
      $element = $(this)
      uc = $element.data('listed-by')
      unless uc
        options = typeof option == 'object' && option
        $element.data('listed-by', (uc = new ListedBy($element, options)))
      uc[option]() if (typeof option == 'string')

  $.fn.listedBy.defaults = {
  }

  # data api
  $('[data-role=listed-by]').listedBy()

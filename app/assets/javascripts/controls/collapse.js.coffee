# A control for collapsible elements. Similar to Bootstrap's collapse widget but implemented using jQuery's +hide()+
# and +show()+ methods rather than Bootstrap's goofy +height: 0+ thing which seems to be really flaky. Additionally,
# this control supports checkbox toggles (link toggles can be added if needed in the future).
#
# To programatically set up a collapsible element, call +copiousCollapse()+ on it.
#
#  $('#something').copiousCollapse()
#
# If you pass a string to +copiousCollapse()+, it is interpreted as the name of a method to call on the toggle:
#
# * +hide()+ - hides the target element
# * +show()+ - shows the target element
#
# Additionally, you can implicitly define a collapsible element in your markup by identifying a checkbox toggle.
# To do this, add the +data-toggle=checkbox+ and +href=<selector>+ attributes to a checkbox, where +<selector>+
# identifies the element to collapse. When the checkbox is checked, the target element is shown; when the checkbox
# is unchecked, the target element is hidden.
#
# The following events are triggered on a collapsible element:
#
# * +cc:hide+ - when it is about to be hidden
# * +cc:hidden+ - when it has been hidden
# * +cc:show+ - when it is about to be shown
# * +cc:shown+ - when it has been shown
#
# For now, only the jQuery default animations for +hide()+ and +show()+ are supported.

class CopiousCollapse
  constructor: (@element, options) ->
    @options = $.extend({}, $.fn.copiousCollapse.defaults, options)

  hide: () ->
    @element.trigger 'cc:hide'
    @element.hide()
    @element.trigger 'cc:hidden'

  show: () ->
    @element.trigger 'cc:show'
    @element.show()
    @element.trigger 'cc:shown'

jQuery ->
  # plugin definition
  $.fn.copiousCollapse = (option) ->
    $(this).each () ->
      $element = $(this)
      cc = $element.data('copious-collapse')
      unless cc
        options = typeof option == 'object' && option
        $element.data('copious-collapse', (cc = new CopiousCollapse($element, options)))
      cc[option]() if (typeof option == 'string')

  $.fn.copiousCollapse.defaults = {
    # no options supportd yet
    # XXX: default animation
  }

  # data api
  $('body').on 'change', '[data-toggle=cc-checkbox]', () ->
    $toggle = $(this)
    $target = $($toggle.data('href'))
    if $toggle.is(':checked')
      $target.copiousCollapse('show')
    else
      $target.copiousCollapse('hide')

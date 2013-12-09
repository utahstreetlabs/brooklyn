#= require jquery.mousewheel
#= require mwheelIntent
#= require jquery.jscrollpane

# A component to add custom JS scrollbars to a page element.
#
# Note: This component should not be used with ScrollableModal as they are not currently compatible.
#
# Uses the jScrollPane jQuery plugin.
# Official page:
#   http://jscrollpane.kelvinluck.com/
# API:
#   http://jscrollpane.kelvinluck.com/api.html
# Settings:
#   http://jscrollpane.kelvinluck.com/settings.html
# Events:
#   http://jscrollpane.kelvinluck.com/events.html
# Source:
#   https://github.com/vitch/jScrollPane
#
# Note: This component uses the jScrollPane jQuery plugin. However, it does not use the plugin from the master branch
#       at the above source. Instead, it uses a separate version that includes a number of bug fixes at:
#   https://github.com/ZhihaoJia/jScrollPane/tree/width-calc
class Scrollable
  @defaultSettings:
    animateScroll: true
    verticalDragMinHeight: 10
    horizontalDragMinWidth: 10

  constructor: (@element) ->
    this._init()

  refresh: (settings) =>
    @scroll.reinitialise(settings)

  getContents: =>
    @scroll.getContentPane().children()

  getContentContainer: =>
    @scroll.getContentPane()

  scrollTo: (target) =>
    if target instanceof HTMLElement
      @scroll.scrollToElement(target, true)
    else if typeof target is 'object'
      if typeof target.x is 'number' and typeof target.y is 'number' then @scroll.scrollTo(target.x, target.y)
      else if typeof target.x is 'number' then @scroll.scrollToX(target.x)
      else if typeof target.y is 'number' then @scroll.scrollToY(target.y)
    else if typeof target is 'string'
      @scroll.scrollToY(0) if target is 'top'
      @scroll.scrollToBottom() if target is 'bottom'

  scrollBy: (distance) =>
    return unless typeof distance is 'object'
    if typeof distance.x is 'number' and typeof distance.y is 'number' then @scroll.scrollBy(distance.x, distance.y)
    else if typeof distance.x is 'number' then @scroll.scrollByX(distance.x)
    else if typeof distance.y is 'number' then @scroll.scrollByY(distance.y)

  _init: =>
    @element
      .addClass('scrollable')
      .jScrollPane(Scrollable.defaultSettings)

    @scroll = @element.data('jsp')
    @container = @element.find('.jspContainer')
    @pane = @element.find('.jspPane')
    @scrollbar =
      vertical: @element.find('.jspVerticalBar')
      horizontal: @element.find('.jspHorizontalBar')

jQuery ->
  $.fn.scrollable = copious.plugin.componentPlugin(Scrollable, 'scrollable')

  $('.scrollable').scrollable()

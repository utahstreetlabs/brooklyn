# Component used to make elements on the page sticky (fixed position on page)
# after scrolling past a given offset on the page.
#
# StickyScroll functions similarly to bootstrap affix, but provides some additional features such as animation.

class StickyScroll
  @defaults =
    offset: 0
    animate: false
    animateDuration: 50
  @animateWinWidthLimit: 1240

  constructor: (@element, options) ->
    options.pos = $.extend({}, StickyScroll.defaults.pos, options.pos)
    @options = $.extend({}, StickyScroll.defaults, options)

    @window = $(window)
    @height = @element.outerHeight()
    @sticky = false

    if @options.offset is 0
      # If element should be sticky on load, it may be hidden by default so as not to take up space on page.
      this.stick()
    else
      @window = $(window).on 'scroll.stickyscroll', => this._checkStick()

  stick: =>
    # Assumes position styling already applied
    @sticky = true
    if @options.animate
      @element
        .css('top', -@height)
        .show()
        .animate {top: 0}, StickyScroll.animateDuration
    else
      @element.show()

  unstick: =>
    @sticky = false
    if @options.animate
      @element.animate {top: -@height}, StickyScroll.animateDuration, =>
          @element.hide()
    else
      @element.hide()

  _checkStick: =>
    @scrollPos = @window.scrollTop()
    if not @sticky and @scrollPos > @options.offset
      this.stick()
    else if @sticky and @scrollPos < @options.offset
      this.unstick()

class StickyHeader extends StickyScroll
  @defaults:
    offset: 300

  constructor: (element) ->
    StickyHeader.defaults.animate = true if window.innerWidth > StickyScroll.animateWinWidthLimit
    super element, StickyHeader.defaults

class StickyFooter extends StickyScroll
  @defaults:
    pos: {bottom: '0px'}
    offset: 300

  constructor: (element) ->
    StickyHeader.defaults.animate = true if window.innerWidth > StickyScroll.animateWinWidthLimit
    super element, StickyFooter.defaults

jQuery ->
  $.fn.stickyHeader = copious.plugin.componentPlugin(StickyHeader, 'stickyHeader')
  $.fn.stickyFooter = copious.plugin.componentPlugin(StickyFooter, 'stickyFooter')

  $('.sticky-header').stickyHeader()
  $('.sticky-footer').stickyFooter()

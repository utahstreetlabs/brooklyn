# A library for toggling between an excerpt of text and the full text.
#
# Expects a DOM with the following structure:
#
# + outermost container
#     + "truncated" container with data-role=excerpt-truncated
#         - full text
#     + control with data-toggle=excerpt, href=<selector of "full" container>,
#           data-text=<selector of "truncated" container>
#     + "full" container with data-role=excerpt-full
#         - full text
#     + control with data-toggle=excerpt, href=<selector of "truncated" container>,
#           data-text=<selector of "full" container>
#
# The "full" container is initially hidden. If there's not enough text within the "truncated" container to exceed the
# number of lines given by the +lineCount+ option, then the control within the "truncated" container is also hidden.
# Otherwise, the "truncated" text is truncated and the control shown. When the "truncated" control is clicked, the
# "truncated" container is hidden and the "full" container is shown. When the "full" control is clicked, the opposite
# happens.
#
# The height of a line is calculated by multiplying the CSS +font-size+ attribute of the outermost container by
# the +lineHeightFontSizeRatio+ option (generally 1.33 or 1.5).
#
# Requires the dotdotdot js library.
#
# Future improvements:
#  * Don't require the text to be provided twice
class Excerpt
  constructor: (@element, options) ->
    @options = $.extend({}, $.fn.excerpt.defaults, options)
    @truncated = $('[data-role=excerpt-truncated]', @element)
    @full = $('[data-role=excerpt-full]', @element)
    # do live lookups for controls so that the dom within the containers can change over time

    @full.hide()

    @truncated.dotdotdot({
      height: @options.lineCount * this.lineHeight()
    })
    # dotdotdot advertises a callback option but the version we're using doesn't seem to support it, so just go with
    # the triggered event approach instead to check whether or not the text was truncated.
    @truncated.trigger 'isTruncated', (isTruncated) =>
      $('[data-toggle=excerpt]', @element).hide() unless isTruncated

    $('[data-toggle=excerpt]', @element).on 'click', () ->
      $toggle = $(this)
      text = $toggle.data('text')
      $(text).hide()                       # text
      $toggle.hide()                       # text toggle
      $($toggle.attr('href')).show()       # target
      $("[href=#{text}]", @element).show() # target toggle
      false

  # http://stackoverflow.com/questions/1185151/how-to-determine-a-line-height-using-javascript-jquery
  lineHeight: () ->
    fontSize = parseInt(@element.css('font-size').replace('px', ''))
    Math.round(fontSize * @options.lineHeightFontSizeRatio)

jQuery ->
  # plugin definition
  $.fn.excerpt = (option) ->
    $(this).each () ->
      $element = $(this)
      e = $element.data('excerpt')
      unless e
        options = typeof option == 'object' && option
        $element.data('excerpt', (e = new Excerpt($element, options)))
      e[option]() if (typeof option == 'string')

  $.fn.excerpt.defaults = {
    lineCount: 2,
    lineHeightFontSizeRatio: 1.5 # adjust if the design changes
  }

  # data api
  $('[data-role=excerpt]').each -> $(this).excerpt()

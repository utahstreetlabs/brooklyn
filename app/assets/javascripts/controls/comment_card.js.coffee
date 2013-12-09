# Requires copious/remote_form and copious/form to also be loaded
#= require controls/commentbox
class CommentCard
  constructor: (@element, options) ->
    @commentUI = $('[data-role=comment-ui]', @element)
    this._initButton()

  showUI: () =>
    this._initBackside()
    @commentUI.show()
    @commentInput.focus()
    this._scrollToCommentStreamBottom()

  hideUI: () =>
    @commentUI.hide()
    this._updateFrontCommentCount()

  isBacksideInitialized: () => @backsideInitialized is true

  _initButton: () =>
    @frontCountElement = $('[data-role=comments-count]', @element)
    @frontContentElement = $('[data-role=comment-button-content]', @element)
    @commentsCount = parseInt(@frontCountElement.text())

  _initBackside: () =>
    return if this.isBacksideInitialized()

    @commentHeader = $('[data-role=product-card-comment-header]', @element)
    @commentInput = $('[data-role=product-card-comment-entry]', @element)
    @commentStream = $('[data-role=product-card-comment-stream]', @element)
    @commentInput.on 'keypress', (e) -> submitOnEnter(this, e)
    @commentInput.val('')

    commentEntryContainer = $('#product-card-comment-entry:first', @element)
    $.remoteForm.initRemoteForm(commentEntryContainer)

    commentEntryForm = $('form', commentEntryContainer)
    commentEntryForm.on 'jsend:success', (e, data) =>
      @commentHeader.html(data.comment_header) if data.comment_header?
      @commentStream.append(data.comment) if data.comment?
      @commentsCount = data.comment_count
      # The current user has commented on the listing, so add the inactive
      # class to the element to make sure the button is highlighted correctly.
      @frontContentElement.addClass('inactive')

      # clear the textarea, setting it back to its placeholder value
      @commentInput.val('')
      @commentInput.focus()
      this._scrollToCommentStreamBottom()
      @element.trigger("listing:commented", [data])
    @backsideInitialized = true

  _updateFrontCommentCount: () =>
   # Sync the comment count from the back of the card with the front.
   @frontCountElement.text(@commentsCount)

  _scrollToCommentStreamBottom: () =>
    @commentStream.scrollTop(@commentStream.children("li:last").offset().top)

jQuery ->
  # plugin definition
  $.fn.commentCard = (option) ->
    $(this).each () ->
      $element = $(this)
      cb = $element.data('comment-button')
      unless cb
        options = typeof option == 'object' && option
        $element.data('comment-button', (cb = new CommentCard($element, options)))
      cb[option]() if (typeof option == 'string')

  $.fn.commentCard.defaults = {}

  # data api
  $('body').on 'click', '[data-action=comment]', () ->
    $(this).closest('[data-flip=card]').commentCard('showUI')
  $('body').on 'flipButton:flippedToFront', '[data-flip=card]', () ->
    $(this).commentCard('hideUI')

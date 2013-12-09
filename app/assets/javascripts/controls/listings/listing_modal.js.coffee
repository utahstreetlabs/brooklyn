#= require constants
#= require controls/excerpt
#= require controls/modal_loader
#= require controls/scrollable
#= require controls/scrollable_modal
#= require copious/form
#= require copious/jsend
#= require copious/remote_form
#= require copious/tracking
#= require handlebars
#= require jquery_ujs

#######################################################################################################################
# ListingModal mainly differs from regular modals in that it has history support for modal URL and browser navigation.
#
# ListingModal follows the plugin and data api models, and requires the listing modal element to be created first
# before initializing the component.
#
# The first time showing the modal should be triggered manually by calling the load function. After loading a listing
# modal for the first time, it should not be loaded again (since it will do nothing).
#
# Listing modals should never be manually toggled or shown.
#
# Toggling and showing of listing modals are managed by the history state change handler. To show a modal, use the
# setListingUrl function and let the handler figure out whether the modal should be shown. Hiding modals with
# $modal.hide would not cause any issues though. Note that the history state should not be changed on any modal show
# or hide event to avoid an infinite loop.
#
# When saving data to the history state with HistoryManager.addData, there are currently three possible actions
# (passed in the action property of saved data). These are 'setup', 'replace', and 'insert'. The action names refer to
# setting up the history state on init, saving over the history state, and saving the data as a new history state
# (after the current one), respectively.
#######################################################################################################################
class ListingModal
  @_ELEMENT_TEMPLATE: Handlebars.compile("""
<div id="{{elementId}}" class="modal modal-large" style="display:none" data-listing="{{listingId}}"
  data-listing-url="{{listingUrl}}" data-url="{{url}}" data-source="{{source}}" data-include-source="true">
  <div class="modal-body">
    <div class="spinner-loading" data-role="spinner" style="display:none">
      <div class="circleG circleG_1"></div>
      <div class="circleG circleG_2"></div>
      <div class="circleG circleG_3"></div>
    </div>
    <div class="alert" data-role="alert" style="display:none"></div>
    <div data-role="modal-content"></div>
  </div>
</div>
""")

  @elementId: (listingId) ->
    "listing-#{listingId}-modal"

  @findElement: (listingId) ->
    elementId = this.elementId(listingId)
    $element = $("##{elementId}")
    if $element.length is 0 then null else $element.first()

  @createElement: (listingId, listingUrl, url, source) ->
    elementId = this.elementId(listingId)
    $element = $(this._ELEMENT_TEMPLATE(
      {elementId: elementId, listingId: listingId, listingUrl: listingUrl, url: url, source: source}
    ))
    $('body').append($element)
    $element

  constructor: (@element) ->
    @id = @element.get(0).id
    @url = @element.data('url')
    @listingId = @element.data('listing')
    @listingUrl = @element.data('listing-url')
    @source = @element.data('source')
    @content = @element.find('[data-role=modal-content]')
    @spinner = @element.find('[data-role=spinner]')
    @alert = @element.find('[data-role=alert]')
    @likeButton = @element.find('[data-toggle=love]')

    @modalSource = 'listing-modal'
    @commentPrepared = false
    @keysBound = false

    @loader = new ModalLoader(@element)
    @history = new ListingModalHistory(this, @element, @id, @listingUrl)
    @saver = new ListingModalSaver(@element, {showListingModal: @history.setListingUrl})
    @element.data('listingHistory', @history)

    @element.scrollableModal()

    @element.on 'show', =>
      this._bindKeys()
      @element.trigger 'listingModal:show'

    @element.on 'hide', =>
      this._unbindKeys()
      @element.trigger 'listingModal:hide'

    $(document).on 'loveButton:loved', @likeButton, (e, data) =>
      @element.find('[data-role=ctas]').replaceWith($(data))

    $(document).on 'saveManager:saved', (e, data) =>
      if data.listingId? and data.listingId is @listingId
        if data.modalCtas?
          @element.find('[data-role=ctas]').replaceWith($(data.modalCtas))

  load: =>
    @element.trigger 'listingModal:load'
    @loader.load().then((data) =>
      this._initContent(data)
    ).fail( =>
      this._logError()
    )

  prepareComment: (commentForm) =>
    $commentForm = if commentForm? then $(commentForm) else $(@commentFormSelector)
    if $commentForm.exists() and not @commentPrepared
      $.remoteForm.initRemoteForm($commentForm)
      $commentForm.data('source', @modalSource)
      @commentPrepared = true

  navigateLeft: =>
    currentIndex = this._getSelectedIndex()
    lastIndex = this._getLastIndex()
    newIndex = if currentIndex is 0 then lastIndex else currentIndex - 1
    this.navigateTo(newIndex)

  navigateRight: =>
    currentIndex = this._getSelectedIndex()
    lastIndex = this._getLastIndex()
    newIndex = if currentIndex is lastIndex then 0 else currentIndex + 1
    this.navigateTo(newIndex)

  navigateTo: (index) =>
    @footerThumbnailWrappers.find("[data-index=#{index}]").click()

  _initContent: (data) =>
    this._initCommentSection()
    this._initTopSection()
    this._initFooterSection()
    @saver.setup(data.saveManager)

  _initCommentSection: =>
    # Use selectors because cached elements are lost after reopening modal.
    @commentSectionSelector = "##{@id} [data-role=comments]"
    @commentStreamSelector = "#{@commentSectionSelector} [data-role=comment-stream]"
    @commentFormSelector = "#{@commentSectionSelector} form"
    @commentInputSelector = "#{@commentFormSelector} textarea"

    this.prepareComment()

    @element.on 'submit', @commentFormSelector, (e) =>
      this._clearInlineErrors()
    @element.on 'jsend:success', @commentFormSelector, (e, data) =>
      @commentPrepared = false
      if data.comment?
        $(@commentSectionSelector).replaceWith(data.comment)
        this._scrollCommentStream($(@commentStreamSelector))
      this.prepareComment()
      @scrollable.refresh({contentWidth: '0px'}) if @scrollable?
      @element.trigger("listing:commented", [data])
    @element.on 'jsend:fail', @commentFormSelector, (e, data) =>
      this._showInlineErrors(data.errors)

    @element.on 'keypress', @commentInputSelector, (e) ->
      submitOnEnter(e.currentTarget, e)

  _initTopSection: =>
    @topSection = @content.find('[data-role=listing-modal-top]')
    @topSection.find('.product-title').dotdotdot(wrap: 'letter')
    @topSection.find('[data-role=excerpt]').excerpt()
    this._scrollCommentStream($(@commentStreamSelector))
    scroll = @topSection.find('.scrollable')
    if scroll.exists()
      @scrollable = scroll.scrollable().data('scrollable')
      # Hack to remove horizontal scroll bar caused by overflow from adding vertical scroll bar.
      @scrollable.refresh({contentWidth: '0px'})
    this._initNavigationSection()

  _initFooterSection: =>
    @footerSection = @content.find('[data-role=listing-modal-footer]')
    @footerThumbnailWrappers = @footerSection.find('[data-role=listing-modal-thumbnails] [data-role=thumbnail-wrapper]')
    @footerThumbnails = @footerThumbnailWrappers.find('[data-role=thumbnail]')
    @footerThumbnails.on 'click', (e, extras) =>
      # When a listing thumbnail is selected, update the modal top (which includes the header+body)
      # with content for that listing.  The footer is not updated.
      $thumbnail = $(e.target)
      this._setSelectedThumbnail($thumbnail)
      options = {
        beforeSend: @loader.spinnerOn,
        complete: @loader.spinnerOff
      }
      query = if $thumbnail.data('collection') then { collection: $thumbnail.data('collection') } else {}
      $.extend(query, {source: @modalSource, page_source: copious.pageSource()})
      $.jsend.get($thumbnail.data('url'), query, options).
        then((data) =>
          this._updateTopContent(data.modalTop)
          @saver.setup(data.saveManager)
          unless extras? and extras.hidden
            this.prepareComment()
            @element.trigger 'listingModal:updated', data
        ).
        fail((status, data) =>
          @loader.showModalError()
          this._logError()
        )
    # Reset the modal to viewing the data associated with the triggering listing.
    @element.on 'hidden', =>
      $targetThumbnail = @footerThumbnails.first()
      $targetThumbnail.trigger 'click', {hidden: true} unless $targetThumbnail[0] is this._getSelectedThumbnail()[0]

  _initNavigationSection: =>
    @navigationSection = @content.find('[data-role=listing-modal-navigation]')
    @navigationControls = @navigationSection.find('[data-action=navigate]')
    @navigationControls.on 'click', (e) =>
      $control = $(e.target)
      if ($control.data('slide') is 'prev')
        this.navigateLeft()
      else if ($control.data('slide') is 'next')
        this.navigateRight()

  # attaching keypress handlers to the document because when I tried attaching to @element the events were
  # only triggered when the comment input had focus.

  _bindKeys: =>
    return if @keysBound
    $(document).on 'keyup', this._handleNavKeyPress
    @keysBound = true

  _unbindKeys: =>
    return unless @keysBound
    $(document).off 'keyup', this._handleNavKeyPress
    @keysBound = false

  _handleNavKeyPress: (e) =>
    # if using the left or right arrows outside the comment box, navigate to the listing in that direction
    return if $(e.target).data('control') is 'commentbox'
    if e.which is KEYCODE_LEFTARROW
      this.navigateLeft()
    else if e.which is KEYCODE_RIGHTARROW
      this.navigateRight()

  _getSelectedThumbnail: =>
    @footerThumbnailWrappers.filter('.selected').find('[data-role=thumbnail]')

  _setSelectedThumbnail: ($thumbnail) =>
    @footerThumbnailWrappers.removeClass('selected')
    $thumbnail.closest("[data-role=thumbnail-wrapper]").addClass('selected')

  _getSelectedIndex: =>
    $(this._getSelectedThumbnail()[0]).data('index')

  _getLastIndex: =>
    @footerThumbnails.last().data('index')

  _updateTopContent: (html) =>
    @topSection.replaceWith(html)
    @commentPrepared = false
    this._initTopSection()

  _showInlineErrors: (errors) =>
    this._showInlineError(field, msgs[0]) for own field, msgs of errors

  _showInlineError: (field, msg) =>
    $commentForm = $(@commentFormSelector)
    $field = $commentForm.find("[name='comment[#{field}]']")
    $field.closest('.control-group').addClass('error')
    $field.after("""<span class="help-block">#{msg}</span>""")

  _clearInlineErrors: =>
    $commentForm = $(@commentFormSelector)
    $commentForm.find('.control-group').removeClass('error')
    $commentForm.find('.help-block').remove()

  _scrollCommentStream: ($stream) =>
    if $stream.children('li').length > 0
      # setTimeout is necessary to get the correct offset on async loaded content
      setTimeout( ->
        $stream.scrollTop($stream.children('li:last').offset().top)
      , 0)

  _logError: =>
    copious.track('listing-modal error', source: @modalSource)

# A component used to manage saving of the listing from the modal.
#
# The saver deals with interaction between the listing modal and save modal.
# Note that the save modal is associated with the listing modal, but must be able to exist outside of the listing
# modal. That is, the user must be able to view and interact with the save modal without the listing modal being
# visible on the page.
#
# The listing modal may contain different listings, and should handle retrieving the save manager for the saver
# to use. The setup function should be called and passed a save manager whenever the listing changes.
class ListingModalSaver
  constructor: (@element, @options) ->
    @saveManager = null
    @allowListingModalShow = false

    @element.on 'click', '[data-action=save-to-collection-cta]', (e) =>
      @element.modal('hide')
      this._prepare($(e.currentTarget))

      $(document).on 'listingModal:show.listingModal saveManager:save.listingModal', =>
        @allowListingModalShow = false

      $(document).on 'saveManager:saved.listingModal', =>
        @allowListingModalShow = true

      $(document).on 'saveManager:closed.listingModal', =>
        if @allowListingModalShow
          this._showListingModal()
          $(document).off '.listingModal'

      $(document).on 'saveManager:succeeded.listingModal', =>
        if @allowListingModalShow
          this._showListingModal()
          $(document).off '.listingModal'

  setup: (saveManager) =>
    @saveManager = saveManager or null

  _prepare: ($saveCta) =>
    $(document.body).append(@saveManager)
    @saveManager = null
    @allowListingModalShow = true

  _showListingModal: =>
    @options.showListingModal() if @options.showListingModal?

class ListingModalHistory
  constructor: (@listingModal, @element, @id, @listingUrl) ->
    ListingModalHistory.title = HistoryManager.components.listingModal

    HistoryManager.addStateHandler(this, ListingModalHistory.title, this._listingModalHistoryHandler)

    @element.on 'hide', =>
      this._revertHistory()

    @element.on 'listingModal:load', =>
      this._setupHistory()
      this._insertHistory()

    @element.on 'listingModal:updated', (e, data) =>
      this._replaceHistory(data)

    @element.on 'click', '[data-history=redirect]', (e) =>
      # Reload page next time user arrives at current history state
      # Handles case where user navigates to listing page from modal (which has same URL as current URL),
      # clicks back browser button, then clicks forward browser button again. Since our handlers would not
      # necessarily exist, we need to save pre-handler-processing option to reload the page.
      # We should also only reload if not opening the new page in a new tab.
      target = $(e.currentTarget).prop('target')
      return if target? and target.length # target may be empty string
      HistoryManager.addData(HistoryManager.PROC_HANDLERS_START, {reload: true})

    @element.on 'click', '[data-history=reload]', (e) =>
      return unless HistoryManager.enabled()
      currParsed = $.url.parse(location.href)
      targetParsed = $.url.parse(e.currentTarget.href)
      if (currParsed.authority + currParsed.path) is (targetParsed.authority + targetParsed.path)
        HistoryManager.addData(HistoryManager.PROC_HANDLERS_START, {reload: true})
        this._replaceHistory({url: e.currentTarget.href}) unless currParsed.anchor is targetParsed.anchor
      else
        location.href = e.currentTarget.href
      location.reload()
      false

  setListingUrl: =>
    return unless HistoryManager.enabled()
    data = HistoryManager.getData(ListingModalHistory.title, {property: @id})
    if data?
      if data.action is 'insert' or data.action is 'replace'
        this._replaceHistory()
      else if data.action is 'setup'
        this._insertHistory()
    else
      # Assume modal content is loading or loaded
      @element.trigger 'load.listingModal'

  _setupHistory: =>
    data = {action: 'setup', url: document.URL}
    HistoryManager.addData(ListingModalHistory.title, data, {property: @id})

  _revertHistory: =>
    data = HistoryManager.getData(ListingModalHistory.title, {property: @id})
    history.back() if data? and (data.action is 'insert' or data.action is 'replace')

  _replaceHistory: (modalData) =>
    url = if modalData? then modalData.url or location.href else @listingUrl
    data = {action: 'replace', url: url}
    HistoryManager.addData(ListingModalHistory.title, data, {property: @id})

  _insertHistory: =>
    data = {action: 'insert', url: @listingUrl}
    HistoryManager.addData(ListingModalHistory.title, data, {property: @id, newEntry: true})

  _listingModalHistoryHandler: (data) =>
    modalData = HistoryManager.getDataProperty(data, @id)
    prevModalData = HistoryManager.getDataProperty(data.prevStateData, @id)
    $modal = $("##{@id}")
    return unless modalData? and $modal.exists()
    if (modalData.action is 'insert' or modalData.action is 'replace') and prevModalData.action is 'setup'
      if $modal.is(':hidden')
        @listingModal.prepareComment()
        $modal.modal('show')
        # The URL may be different from the listing URL if a listing from the modal footer was selected when last open.
        # We cannot correct the URL on hide or it would cause infinite loop.
        this._replaceHistory() if modalData.action is 'replace'
    else if modalData.action is 'setup'
      $modal.modal('hide') if $modal.not(':hidden').exists()


jQuery ->
  # plugin api
  $.fn.listingModal = (option) ->
    $(this).each ->
      $element = $(this)
      data = $element.data('listingModal')
      unless data?
        $element.data('listingModal', (data = new ListingModal($element)))
      if typeof option is 'string'
        data[option].call($element)

  # data api
  $(document).on 'click.modal', '[data-toggle=listing-modal]', (e) ->
    # Previously, encountering an XHR error allowed the click action to propagate, which redirected the user.
    # Prevent click action until able to consistently reproduce the issue and find the exact cause.
    e.preventDefault()
    $toggle = $(this)
    listingId = $toggle.data('listing')
    $modal = ListingModal.findElement(listingId)
    if $modal?
      $modal.modal('toggle') unless HistoryManager.enabled()
      # Call setListingUrl; if content was added dynamically to page, this will update it
      # Cannot call this on 'show' or 'shown' events because it will cause infinite loop with HistoryManager handler
      $modal.data('listingHistory').setListingUrl()
    else
      listingUrl = $toggle.attr('href') or $toggle.data('target')
      url = $toggle.data('url')
      source = copious.source($toggle)
      $modal = ListingModal.createElement(listingId, listingUrl, url, source)
      $modal.listingModal()
      $modal.modal('toggle') unless HistoryManager.enabled()
      # Manually load modal only on creation as it is handled by HistoryManager after init.
      $modal.data('listingModal').load()
    $.rails.stopEverything(e)

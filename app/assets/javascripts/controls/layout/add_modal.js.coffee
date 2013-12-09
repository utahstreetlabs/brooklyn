#= require copious/tracking

class AddModal
  @ADD_LISTING_COPIOUS_BUTTON_SELECTOR = '#add-modal-add-listing-copious-button'

  constructor: (@modal) ->
    @trigger = null
    @username = @modal.data('user')
    @addListingFromWebButton = $('[data-role=add-listing-from-web]', @modal)
    @addCollectionButton = $('[data-role=add-collection]', @modal)
    @bookmarkletButton = $('[data-role=get-bookmarklet]', @modal)

    # it's tempting to create public api methods for these event handlers, but they don't represent behavior that's
    # part of the public lifecycle of the addWidget.

    @addListingFromWebButton.on 'click', =>
      # prefer the add from web button's source if it has one, but fall back to the modal's source if it doesn't
      source = @addListingFromWebButton.data('source') || @source()
      copious.track('add_listing_modal_web click', username: @username, source: source)
      @modal.modal('hide')

    @addCollectionButton.on 'click', =>
      copious.track('add_listing_modal_collection click', username: @username, source: @source())
      $(@addCollectionButton.data('target')).data('source', @source())
      @modal.modal('hide')

    @bookmarkletButton.on 'click', =>
      copious.track('add_listing_modal_bookmarklet click', username: @username, source: @source())

    copious.track_links(AddModal.ADD_LISTING_COPIOUS_BUTTON_SELECTOR, 'add_listing_modal_copious click',
                        => { username: @username, source: @source() })

  source: () ->
    @trigger.data('source') if @trigger

  add: (trigger) ->
    @trigger = $(trigger)
    # need to track view here rather than in response to the modal's "shown" event
    # because this gets called after the modal's "shown" event and @trigger hasn't
    # been updated when that gets handled
    # XXX: patch bootstrap to pass a reference to the trigger through show/shown events
    copious.track('add_listing_modal view', username: @username, source: @source())

jQuery ->
  # plugin api
  $.fn.addModal = (option) ->
    # convert arguments to an array, thanks http://debuggable.com/posts/turning-javascript-s-arguments-object-into-an-array:4ac50ef8-3bd0-4a2d-8c2e-535ccbdd56cb
    modalArgs = Array.prototype.slice.call(arguments)
    $(this).each ->
      $element = $(this)
      data = $element.data('addModal')
      unless data?
        $element.data('addModal', (data = new AddModal($element)))
      if typeof option is 'string'
        data[option].apply(data, modalArgs[1..])

  $('[data-role=add-modal]').addModal()

  $(document).on 'click.modal.data-api', '[data-role=add-widget]', ->
    $('[data-role=add-modal]').addModal('add', this)


#= require copious

# A modal for saving listings to a collection.
#
# Currently, mostly implements special behavior when users select
# "have" or "want" collections.
class CollectionModal
  constructor: (@element, options = {}) ->
    @modal = @element
    @formCollectionIdInput = $('[data-role=collection-id]', 'form', @modal)
    @formCommentInput = $('[data-role=comment]', 'form', @modal)
    @modal.on 'jsend:success', (e, data) =>
      @formCommentInput.val('')
    @collectionSelector = options.selector
    @have = @modal.find('[data-role=have]')
    @haveCheckbox = $('input[type=checkbox]', @have)
    @want = @modal.find('[data-role=want]')
    @wantCheckbox = $('input[type=checkbox]', @want)
    this._init()

  clearHave: () =>
    @have.hide()
    @haveCheckbox.prop('checked', false)

  setHave: () =>
    @have.show()
    @haveCheckbox.prop('checked', true)

  clearWant: () =>
    @wantCheckbox.prop('checked', false)

  setWant: () =>
    @wantCheckbox.prop('checked', true)

  _init: =>
    if @collectionSelector
      @collectionSelector.on 'collection:haveSelected', (e) =>
        this.setHave()

      @collectionSelector.on 'collection:haveUnselected', (e) =>
        this.clearHave()

      @collectionSelector.on 'collection:wantSelected', (e) =>
        this.setWant()

      @collectionSelector.on 'collection:wantUnselected', (e) =>
        this.clearWant()

jQuery ->
  window.CollectionModal = CollectionModal

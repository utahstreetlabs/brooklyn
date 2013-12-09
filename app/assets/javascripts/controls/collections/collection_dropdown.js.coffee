#= require copious/plugin
#= require copious/form
#= require copious/remote_form
#= require controls/collections/collection_modal
#= require controls/collections/new_collection_input

# A dropdown for selecting or creating a new collection.
#
# Instantiates a NewCollectionInput for collection creation.
#
# Events:
#
# +collection:wantSelected+ triggered when a user selects a "want" collection
# +collection:wantUnselected+ triggered when a user unselects a "want" collection
# +collection:haveSelected+ triggered when a user selects a "have" collection
# +collection:haveUnselected+ triggered when a user unselects a "have" collection
#
class CollectionDropdown
  @updateAll: (html) ->
    $('[data-role=collections-list] [data-role=dropdown-menu]').replaceWith(html)

  constructor: (@element, options) ->
    @dropdown = @element
    @newCollectionInput = $('[data-role=name-input]', @dropdown).newCollectionInput()
    @dropdownForm = @dropdown.closest('form')
    this._init()
    @loaded = true

  hideUI: =>
    @dropdown.removeClass('open') if @dropdown.hasClass('open')

  # The title of a bootstrap dropdown is the contents of its toggle link
  setTitle: (text, id) =>
    if text?
      # Change the text of the node without clobbering the child (caret) node.
      $('[data-role=dropdown-title]', @dropdown)[0].childNodes[0].nodeValue = text
    @dropdownForm.find('[data-role=collection-id]').val(id)

  triggerCollectionTypeEvent: (type) =>
    if type is 'want'
      @dropdown.trigger('collection:wantSelected')
      @dropdown.trigger('collection:haveUnselected')
    else if type is 'have'
      @dropdown.trigger('collection:haveSelected')
      @dropdown.trigger('collection:wantUnselected')
    else
      @dropdown.trigger('collection:haveUnselected')
      @dropdown.trigger('collection:wantUnselected')

  # Add a new item to the dropdown list, if it's not already there.
  addDropdownItem: (id, listItem) =>
    return unless id? and listItem?
    $item = $("[data-collection-id=#{id}]")
    unless $item.length > 0
      $('[data-role=collections-list] [data-role=divider]').before(listItem)
      # Sets up the new list item we just inserted.
      this._initDropdownItems()

  resetDropdown: (hide) =>
    this.hideUI() if hide
    this.clearDropdownErrors()

  clearDropdownErrors: =>
    @dropdown.find('[data-role=name-input] [data-role=add-collection-errors]').remove()

  _init: =>
    return if @loaded
    this._registerEventHandlers()
    this._initDropdownItems()
    # Set the collection type parameters of our default collection
    $defaultItem = $('[data-role=dropdown-menu] li', @dropdown).first()
    if $defaultItem.exists?
      this._selectListItem($defaultItem)

  _registerEventHandlers: =>
    @newCollectionInput.on 'newCollectionInput:created', (e, data) =>
      this.setTitle(data.name, data.id)
      this.addDropdownItem(data.id, data.list_item)
      this.resetDropdown(true)

    @newCollectionInput.on 'newCollectionInput:creationFailed', (e, data) =>
      # This will remove any existing previous errors before adding new ones
      this.resetDropdown(false)
      if data.errors
        $nameField = @dropdown.find('[data-role=name-input]')
        _.each data.errors, (error) =>
          $nameField.append("<span data-role='add-collection-errors' class='help-inline error'>#{error}</span>")
    # Short circuit click.dropdown to ensure the dropdown doesn't
    # close when the new collection input is clicked.
    @newCollectionInput.on 'click.dropdown.data-api', ->
      false

  _selectListItem: ($item) =>
    $link = $('a:not([data-action=add-collection])', $item)
    this.setTitle($link.text(), $item.data('collection-id'))
    this.triggerCollectionTypeEvent($item.data('collection-type'))

  _initDropdownItems: =>
    $('[data-role=dropdown-menu] li', @dropdown).each (i, item) =>
      $link = $('a:not([data-action=add-collection])', $(item))
      $link.on 'click', =>
        this._selectListItem($(item))
        this.resetDropdown(true)
        false

jQuery ->
  $.fn.collectionDropdown = copious.plugin.componentPlugin(CollectionDropdown, 'collectionDropdown')

  # data api
  $('body').on 'click', '[data-role=collections-list] [data-toggle=dropdown]', (e) ->
    $(this).closest('[data-role=collections-list]').collectionDropdown()

  window.CollectionDropdown = CollectionDropdown

  $(document).on 'collectionDropdown:refresh', (e, html) ->
    CollectionDropdown.updateAll(html)

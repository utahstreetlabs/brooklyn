class EditCollectionModal
  constructor: (@element) ->
    this.registerEventHandlers()

  registerEventHandlers: =>
    @element.siblings().find('[data-action=delete-collection]').on('click', ->
      $(this).closest('[data-role=collection-edit-modal]').modal('hide')
    ).on 'jsend:success', ->
      $(this).closest('[data-role=collection-edit-modal-delete]').modal('hide')

jQuery ->
  # plugin api
  $.fn.editCollectionModal = (option) ->
    $(this).each ->
      $element = $(this)
      data = $element.data('editCollectionModal')
      unless data?
        $element.data('editCollectionModal', (data = new EditCollectionModal($element)))
      if typeof option is 'string'
        data[option].call($element)

  # data api
  $(document).on 'click', '[data-action=edit-collection]', (e) ->
    $(this).editCollectionModal()

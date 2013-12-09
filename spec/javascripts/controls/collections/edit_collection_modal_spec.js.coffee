#= require spec_helper
#= require copious/modal
#= require controls/collections/edit_collection_modal

describe 'collections.EditCollectionModal', ->
  beforeEach ->
    $('body').html(JST['templates/controls/collections/edit_collection_modal']())
    $('[data-action=edit-collection]').click()

  describe 'when triggering the delete followup from the edit modal', ->
    it 'hides the initial modal', ->
      $('[data-role=collection-edit-modal] [data-action=delete-collection]').click()
      expect($('[data-role=collection-edit-modal]')).to.be.hidden

  describe 'when successfully deleting a collection', ->
    it 'hides the followup modal', ->
      $('[data-role=collection-edit-modal]  [data-action=delete-collection]').trigger('jsend:success', {})
      expect($('[data-role=collection-edit-modal-delete]')).to.be.hidden

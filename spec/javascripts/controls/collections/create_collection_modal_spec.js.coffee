#= require spec_helper
#= require controls/collections/create_collection_modal

describe 'collections.CreateCollectionModal', ->
  beforeEach ->
    $('body').html(JST['templates/controls/collections/create_collection_modal']())
    $('#collection-create-modal').modal('show')

  describe 'completing the create collection request successfully', ->
    it 'hides the modal', ->
      $('#collection-create-modal').trigger('jsend:success', {})
      expect($('#collection-create-modal')).to.be.hidden

    it 'triggers a refresh of any dropdown menus', ->
      spy = sinon.stub()
      $(document).on 'collectionDropdown:refresh', ->
        spy()
      $('#collection-create-modal').trigger('jsend:success',
        {id: '1234', dropdownMenu: '<ul data-role="dropdown-menu"></ul>'})
      spy.should.have.been.called

  describe 'hiding the modal', ->
    beforeEach ->
      $('#collection-create-modal').modal('hide')

    it 'unsets the modal data source', ->
      expect($('#collection-create-modal').data('source')).to.be.undefined

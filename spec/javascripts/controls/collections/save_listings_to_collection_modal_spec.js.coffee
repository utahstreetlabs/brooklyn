#= require spec_helper
#= require controls/collections/save_listings_to_collection_modal

describe 'collections.SaveListingsToCollectionModal', ->
  beforeEach ->
    $('body').html(JST['templates/controls/collections/save_listings_to_collection_modal']())

  describe 'showing the modal', ->
    beforeEach ->
      $('#listings-modal').modal('show')

    it 'attaches a multiselector', ->
      expect($('#listings-modal [data-role=modal-content]').data('multiselector')).to.be

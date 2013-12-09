#= require spec_helper
#= require controls/collections/add_collection_card

describe 'collections.AddCollectionCard', ->
  tracker = null

  beforeEach ->
    $('body').html(JST['templates/controls/collections/add_collection_card']())
    tracker = sinon.spy(copious, 'track')

  afterEach ->
    tracker.restore()

  describe 'clicking the add collection button', ->
    beforeEach ->
      $('#add-collection-card-button').click()

    it 'tracks the click', ->
      # page source is undefined because konacha ignores any body tag in the template
      args = {username: 'starbuck', source: 'add-collection-card', pageSource: undefined}
      expect(tracker).to.have.been.calledWith('add_listing_modal_collection click', args)

    it 'sets the modal data source', ->
      expect($('#collection-create-modal').data('source')).to.equal('add-collection-card')

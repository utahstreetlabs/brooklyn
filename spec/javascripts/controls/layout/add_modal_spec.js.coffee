#= require spec_helper
#= require controls/layout/add_modal

describe 'layout.AddModal', ->
  tracker = null

  beforeEach ->
    $('body').html(JST['templates/controls/layout/add_modal']())
    tracker = sinon.spy(copious, 'track')
    # page source is always undefined because konacha ignores any body tag in the template
    $('#add-modal').addModal()

  afterEach ->
    tracker.restore()

  describe 'clicking the add listing button', ->
    beforeEach ->
      $('#add-button').click()

    it 'tracks the view', ->
      args = {username: 'starbuck', pageSource: undefined, source: 'a-test'}
      expect(tracker).to.have.been.calledWith('add_listing_modal view', args)

    describe 'clicking the add listing from web button', ->
      beforeEach ->
        $('#add-modal-add-listing-from-web-button').click()

      it 'tracks the click', ->
        args = {username: 'starbuck', source: 'a-test', pageSource: undefined}
        expect(tracker).to.have.been.calledWith('add_listing_modal_web click', args)

      it 'hides the add listing modal', ->
        expect($('#add-modal')).to.be.hidden

    describe 'clicking the add collection button', ->
      beforeEach ->
        $('#add-modal-add-collection-button').click()

      it 'tracks the click', ->
        args = {username: 'starbuck', source: 'a-test', pageSource: undefined}
        expect(tracker).to.have.been.calledWith('add_listing_modal_collection click', args)

      it 'sets the modal data source', ->
        expect($('#collection-create-modal').data('source')).to.equal('a-test')

      it 'hides the add listing modal', ->
        expect($('#add-modal')).to.be.hidden

  # XXX: find a way to test link tracking

#= require spec_helper
#= require layout/masthead

describe 'layout/masthead', ->
  tracker = null

  beforeEach ->
    $('body').html(JST['templates/layout/masthead']())

  describe 'clicking the add button', ->
    beforeEach ->
      $('body').data('page-source', 'test')
      tracker = sinon.spy(copious, 'track')
      $('#masthead-add-button').click()

    afterEach ->
      tracker.restore()

    it 'tracks the click', ->
      args = {username: 'starbuck', page_source: 'test', source: 'masthead-add-button'}
      expect(tracker).to.have.been.calledWith('nav_add click', args)

  describe 'opening the left nav tray', ->
    beforeEach ->
      $(document).trigger 'hamburger:opened'

    it 'slides the page over', ->
      expect($('#root')).to.have.class('hamburger-opened')

    describe 'and then closing it', ->
      beforeEach ->
        $(document).trigger 'hamburger:closed'

      it 'slides the page back', ->
        expect($('#root')).to.not.have.class('hamburger-opened')

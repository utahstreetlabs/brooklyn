#= require spec_helper
#= require controls/layout/hamburger

describe 'layout.Hamburger', ->
  this.timeout(500)
  initializeHamburger = ->
    $('#hb-hamburger').hamburger($('#hb-tray'))
  openHamburger = ->
    $('#hb-hamburger').data('hamburger').open(false)
  closeHamburger = ->
    $('#hb-hamburger').data('hamburger').close(false)

  beforeEach ->
    $('body').html(JST['templates/controls/layout/hamburger']())
    $('body').data('page-source', 'test')
    # can't initialize the hamburger plugin yet because at least one test relies on setting up some state before
    # doing that to assert some document ready behavior
    # initializeHamburger()

  describe 'when the button is clicked', ->
    this.timeout(1000)
    beforeEach ->
      initializeHamburger()
      # ensure hamburger is closed as it may be open by default
      closeHamburger()
      $('[data-toggle=hamburger]').click()

    it 'opens the tray', (done) ->
      setTimeout( ->
        expect($('#hb-tray')).to.have.css('left', '0px')
        done()
      , 900)

    it 'activates the button', ->
      expect($('[data-toggle=hamburger]')).to.have.class('active')

    describe 'and then clicked again', ->
      beforeEach ->
        $('[data-toggle=hamburger]').click()

      it 'closes the tray', (done) ->
        setTimeout( ->
          expect(parseInt($('#hb-tray').css('left'))).to.be.below(0)
          done()
        , 600)

      it 'deactivates the button', ->
        expect($('[data-toggle=hamburger]')).to.not.have.class('active')

    # XXX: for some reason the mock server is no longer stepping in, which means the request goes back to konacha
    # and the main test page is loaded into the iframe and everything goes to shit
#    describe 'and a search is performed', ->
#      server = null

#      beforeEach ->
#        initializeHamburger()
#        server = new MockServer
#        server.respondWith(null)
#        # the response is irrelevant; we're just testing on submit behavior
#        $('#search-box').val('zombies')
#        $('#search-form').submit()

#      afterEach ->
#        server.respond()
#        server.tearDown()

#      it 'shows the spinner', ->
#        expect($('#spinner')).to.be.visible

  describe 'when new stories are available', ->
    beforeEach ->
      initializeHamburger()
      $('[data-role=story-pill]').html("5")
      $('[data-role=story-pill]').trigger('storycount:updated', 5)

    it 'show the hamburger pill', ->
      expect($('[data-role=total-pill]')).to.be.visible

    it 'updates the hamburger pill count', ->
      expect($('[data-role=total-pill]')).to.have.text("5")

  describe 'when no new stories are available', ->
    beforeEach ->
      initializeHamburger()
      $('[data-role=story-pill]').html("0")
      $('[data-role=story-pill]').trigger('storycount:updated', 0)

    it 'hides the hamburger pill', ->
      expect($('[data-role=total-pill]')).to.be.hidden

    it 'resets the hamburger pill count', ->
      expect($('[data-role=total-pill]')).to.not.have.text

  describe 'when unread notifications are available', ->
    beforeEach ->
      initializeHamburger()
      $('[data-role=notification-pill]').html("5")
      $('[data-role=notification-pill]').trigger('notificationcount:updated', 5)

    it 'show the hamburger pill', ->
      expect($('[data-role=total-pill]')).to.be.visible

    it 'updates the hamburger pill count', ->
      expect($('[data-role=total-pill]')).to.have.text("5")

  describe 'when no unread notifications are available', ->
    beforeEach ->
      initializeHamburger()
      $('[data-role=notification-pill]').html("0")
      $('[data-role=notification-pill]').trigger('notificationcount:updated', 0)

    it 'hides the hamburger pill', ->
      expect($('[data-role=total-pill]')).to.be.hidden

    it 'resets the hamburger pill count', ->
      expect($('[data-role=total-pill]')).to.not.have.text

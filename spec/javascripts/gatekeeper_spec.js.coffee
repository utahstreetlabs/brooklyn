#= require spec_helper
#= require gatekeeper

describe 'Gatekeeper', ->
  window.copiousFb ||= {
    logIn: ->
  }
  window.COPIOUSFB = {
    postInit: (callback) ->
      callback()
  }

  loadTemplate = ->
    # causes document ready event to fire
    $('body').html(JST['templates/gatekeeper']())

  describe 'on document ready', ->
    describe 'when immediate auth policy is in effect', ->
      spy = null

      beforeEach ->
        spy = sinon.stub($(document).gatekeeper('instance'), 'enterSignupFlow')
        $('head').append('<meta name="copious:auth-policy" content="protected">')
        loadTemplate()

      afterEach ->
        $('meta[name="copious:auth-policy"]').remove()

      it 'starts manual auth', ->
        spy.should.have.beenCalled

  describe 'api', ->
    subject = null

    beforeEach ->
      loadTemplate()
      subject = new Copious.Gatekeeper

    describe '#enterSignupFlow', ->
      afterEach ->
        $('meta[name="copious:signup-entry-point"]').remove()

      describe 'when the signup entry point is the FB OAuth dialog', ->
        beforeEach ->
          $('head').append('<meta name="copious:signup-entry-point" content="fb">')
          subject._configureSignupEntryPoint()

        it 'invokes the FB api', ->
          spy = sinon.stub(copiousFb, 'logIn')
          subject.enterSignupFlow()
          spy.should.have.been.called
          spy.restore()

      describe 'when the signup entry point is the signup modal', -> # which it is by default
        it 'shows the signup modal', ->
          subject.enterSignupFlow()
          $('#signup-modal').should.be.visible

    describe '#_configureControlProtection', ->
      afterEach ->
        $('meta[name="copious:auth-policy"]').remove()

      describe 'when auth policy is any', ->
        beforeEach ->
          $('head').append('<meta name="copious:auth-policy" content="any">')
          subject._configureControlProtection()

        it 'shows the signup modal when an implicitly protected control is used', ->
          $('a').first().click()
          $('#signup-modal').should.be.visible

        it 'shows the signup modal when an explicitly protected control is used', ->
          $('[data-protected]').first().click()
          $('#signup-modal').should.be.visible

        it 'does not protect controls within the signup modal', ->
          # set up the signup modal's button to hide the modal so that we can tell that the button wasn't protected
          # by asserting that the modal is hidden after the button is clicked
          $('#signup-modal button').on 'click', -> $('#signup-modal').modal('hide')
          $('a').first().click()
          $('#signup-modal').should.be.visible
          $('#signup-modal button').click()
          $('#signup-modal').should.be.hidden

        it 'does not show the signup modal', ->
          $('#signup-modal').should.be.hidden

      describe 'when auth policy is protected', ->
        beforeEach ->
          $('head').append('<meta name="copious:auth-policy" content="protected">')
          subject._configureControlProtection()

        it 'shows the signup modal when a protected control is used', ->
          $('[data-protected]').first().click()
          $('#signup-modal').should.be.visible

        it 'does not show the signup modal when an unprotected control is used', ->
          $('a').first().click()
          $('#signup-modal').should.be.hidden

        it 'does not show the signup modal', ->
          $('#signup-modal').should.be.hidden

    describe '#goToOriginalDestination', ->
      it 'shows the logging in modal and its spinner', ->
        spy = sinon.stub(subject, '_redirectWindow')
        subject.goToOriginalDestination(location.href)
        $('#logging_in-modal').should.be.visible
        $('#logging_in-modal .spinner').should.be.visible

      describe 'when there is a destination url', ->
        destination = '/foo/bar'
        url = "#{location.href}?d=#{encodeURI destination}"

        it 'shows the logging in modal and its spinner and redirects the window to the destination url', ->
          spy = sinon.stub(subject, '_redirectWindow').withArgs(destination)
          subject.goToOriginalDestination(url)
          $('#logging_in-modal').should.be.visible
          $('#logging_in-modal .spinner').should.be.visible
          spy.should.have.been.called

      describe 'when there is no destination url', ->
        url = location.href

        it 'reloads the window', ->
          spy = sinon.stub(subject, '_redirectWindow').withArgs(url)
          subject.goToOriginalDestination(url)
          $('#logging_in-modal').should.be.visible
          $('#logging_in-modal .spinner').should.be.visible
          spy.should.have.been.called

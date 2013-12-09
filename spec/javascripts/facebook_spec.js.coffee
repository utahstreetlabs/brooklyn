#= require spec_helper
#= require facebook

describe 'Facebook', ->
  initializeFacebook()

  beforeEach ->
    $('body').html(JST['templates/facebook']())

  describe 'Receiving the auth.statusChange event', ->
    describe 'when the user is logged into FB and has authenticated the Copious app', ->
      beforeEach ->
        response =
          status: 'connected'
          authResponse:
            accessToken: 'deadbeef'
            signedRequest: 'cafebebe'
        FB.Event.trigger 'auth.statusChange', response

      it 'remembers that the user is logged in to FB', ->
        expect(copiousFb.isLoggedIn()).to.be.true

      it 'remembers that the user has authenticated the Copious app', ->
        expect(copiousFb.hasAuthenticatedApp()).to.be.true

    describe 'when the user is logged into FB but has not authenticated the Copious app', ->
      beforeEach ->
        response =
          status: 'not_authorized'
        FB.Event.trigger 'auth.statusChange', response

      it 'remembers that the user is logged in to FB', ->
        expect(copiousFb.isLoggedIn()).to.be.true

      it 'remembers that the user has not authenticated the Copious app', ->
        expect(copiousFb.hasAuthenticatedApp()).to.be.false

    describe 'when the user is not logged into FB', ->
      beforeEach ->
        response =
          status: 'unknown'
        FB.Event.trigger 'auth.statusChange', response

      it 'remembers that the user is not logged in to FB', ->
        expect(copiousFb.isLoggedIn()).to.be.false

      it 'remembers that the user has not authenticated the Copious app', ->
        expect(copiousFb.hasAuthenticatedApp()).to.be.false

  describe 'Clicking the FB connect button', ->
    login = null
    enterAuthFlow = null

    beforeEach ->
      login = sinon.stub(FB, 'ui')
      enterAuthFlow = sinon.stub(CopiousFb, 'enterAuthFlow')

    afterEach ->
      login.restore()
      enterAuthFlow.restore()

    describe 'and logging in to FB and authenticating the Copious app', ->
      beforeEach ->
        login.yields {status: 'connected'}
        $('#fb-connect').click()

      it 'remembers that the user is logged in to FB', ->
        expect(copiousFb.isLoggedIn()).to.be.true

      it 'remembers that the user has authenticated the Copious app', ->
        expect(copiousFb.hasAuthenticatedApp()).to.be.true

      it 'enters the Copious auth flow', ->
        expect(enterAuthFlow).to.have.been.called

    describe 'and logging in to FB but not authenticating the Copious app', ->
      beforeEach ->
        login.yields {status: 'not_authorized'}
        $('#fb-connect').click()

      it 'remembers that the user is logged in to FB', ->
        expect(copiousFb.isLoggedIn()).to.be.true

      it 'remembers that the user has not authenticated the Copious app', ->
        expect(copiousFb.hasAuthenticatedApp()).to.be.false

      it 'enters the Copious auth flow', ->
        expect(enterAuthFlow).to.have.been.called

    describe 'but not logging into FB', ->
      beforeEach ->
        login.yields {status: 'unknown'}
        $('#fb-connect').click()

      it 'remembers that the user is not logged in to FB', ->
        expect(copiousFb.isLoggedIn()).to.be.false

      it 'remembers that the user has not authenticated the Copious app', ->
        expect(copiousFb.hasAuthenticatedApp()).to.be.false

      it 'does not enter the Copious auth flow', ->
        expect(enterAuthFlow).to.not.have.been.called

  describe 'Clicking the Copious login button', ->
    describe 'when the user is logged into FB and has authenticated the Copious app', ->
      beforeEach ->
        copiousFb.auth.status = 'connected'
        copiousFb.auth.token = 'deadbeef'
        copiousFb.auth.signed = 'cafebebe'
        $('#copious-login').click()

      afterEach ->
        copiousFb.auth.status = null
        copiousFb.auth.token = null
        copiousFb.auth.signed = null

      it 'sets the FB access token in the login form', ->
        expect($('#login_facebook_token')).to.have.value('deadbeef')

      it 'sets the FB signed request in the login form', ->
        expect($('#login_facebook_signed')).to.have.value('cafebebe')

    describe 'when the user is logged into FB but has not authenticated the Copious app', ->
      beforeEach ->
        beforeEach ->
          copiousFb.auth.status = 'not_authorized'
          $('#copious-login').click()

        afterEach ->
          copiousFb.auth.status = null

      it 'does not set an FB access token in the login form', ->
        expect($('#login_facebook_token')).to.have.value('')

      it 'does not set an FB signed request in the login form', ->
        expect($('#login_facebook_signed')).to.have.value('')


    describe 'when the user is not logged into FB', ->
      beforeEach ->
        beforeEach ->
          copiousFb.auth.status = 'unknown'
          $('#copious-login').click()

        afterEach ->
          copiousFb.auth.status = null

      it 'does not set an FB access token in the login form', ->
        expect($('#login_facebook_token')).to.have.value('')

      it 'does not set an FB signed request in the login form', ->
        expect($('#login_facebook_signed')).to.have.value('')

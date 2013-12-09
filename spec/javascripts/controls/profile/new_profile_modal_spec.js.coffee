#= require spec_helper
#= require controls/profile/new_profile_modal

describe 'New profile modal', ->
  subject = null
  form = null
  saveButton = null
  server = null

  beforeEach ->
    $('body').html(JST['templates/controls/profile/new_profile_modal']())
    server = new MockServer

  describe 'auth flow', ->
    server = null
    spy = null

    describe 'and registered with Copious', ->
      beforeEach ->
        server.respondWith('/auth/facebook/callback?s=b', data: {status: 'success', data: {user_state: 'registered'}})
        subject = $('#new-profile-modal').newProfileModal('instance')
        spy = sinon.spy(subject, 'reloadPage')
        server.respond()

      it 'reloads the page', ->
        spy.should.have.been.called

    describe 'and logged in to Copious', ->
      beforeEach ->
        server.respondWith('/auth/facebook/callback?s=b', data: {status: 'success', data: {user_state: 'logged_in'}})
        subject = $('#new-profile-modal').newProfileModal('instance')
        spy = sinon.spy(subject, 'reloadPage')
        server.respond()

      it 'reloads the page', ->
        spy.should.have.been.called

    describe 'and connected to Copious', ->
      beforeEach ->
        server.respondWith('/auth/facebook/callback?s=b', data: {status: 'success', data: {user_state: 'connected'}})
        subject = $('#new-profile-modal').newProfileModal('instance')
        spy = sinon.spy(subject, 'showModal')
        server.respond()

      it 'shows the new profile modal', ->
        spy.should.have.been.called

    describe 'but logging into Copious fails', ->
      beforeEach ->
        spy = sinon.stub(copious.flash, 'alert')
        server.respondWith('/auth/facebook/callback?s=b', data: {status: 'error', code: 500, data: {}})
        subject = $('#new-profile-modal').newProfileModal('instance')
        server.respond()

      it 'shows an error', ->
        spy.should.have.been.called


  describe 'modal functionality', ->
    beforeEach ->
      $('body').html(JST['templates/controls/profile/new_profile_modal']())
      server = new MockServer
      response = {user_state: 'connected', profileForm: JST['templates/controls/profile/new_profile_form']()}
      server.respondWith('/auth/facebook/callback?s=b', data: {status: 'success', data: response})
      subject = $('#new-profile-modal').newProfileModal('instance')
      server.respond()
      form = subject.modal.find('form')
      saveButton = subject.modal.find('[data-save=modal]')

    describe 'form submission', ->
      it 'should submit the profile creation form when the save button is clicked', ->
        submitSpy = sinon.spy()
        form.on 'submit', ->
          submitSpy()
          false
        saveButton = subject.modal.find('[data-save=modal]')
        saveButton.click()
        expect(submitSpy).to.have.been.called

    describe 'save button', ->
      it 'is enabled when the form is valid', ->
        form.trigger('newProfileForm:valid')
        expect(saveButton.prop('disabled')).to.be.false

      it 'is disabled when the form is invalid', ->
        form.trigger('newProfileForm:invalid')
        expect(saveButton.prop('disabled')).to.be.true

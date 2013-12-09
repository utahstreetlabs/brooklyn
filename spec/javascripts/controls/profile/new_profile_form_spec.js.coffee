#= require spec_helper
#= require controls/profile/new_profile_form

describe 'New profile form', ->
  subject = null
  form = null
  validHandler = null
  invalidHandler = null
  submitHandler = null
  emailInput = null
  passwordInput = null

  beforeEach ->
    $('body').html(JST['templates/controls/profile/new_profile_form']())
    form = $('[data-role=new-profile-form]').newProfileForm()
    validHandler = sinon.spy()
    invalidHandler = sinon.spy()
    submitHandler = sinon.spy()
    form.on 'newProfileForm:valid', -> validHandler()
    form.on 'newProfileForm:invalid', -> invalidHandler()
    form.on 'submit', (e) -> submitHandler()
    subject = form.newProfileForm('instance')
    emailInput = form.find('input[name="user[email]"]')
    passwordInput = form.find('input[name="user[password]"]')

  expectFormToBeValid = ->
    expect(validHandler).to.have.been.called

  expectFormToBeInvalid = ->
    expect(invalidHandler).to.have.been.called

  expectFormSubmission = ->
    expect(submitHandler).to.have.been.called

  enterPassword = (password) ->
    passwordInput.val(password)
    Test.triggerKeyUp(passwordInput, KEYCODE_SPACE)

  enterEmail = (email) ->
    emailInput.val(email)
    Test.triggerKeyUp(emailInput, KEYCODE_SPACE)

  describe 'validation', ->
    it 'should not be checked on load', ->
      expect(invalidHandler).to.not.have.been.called
      expect(validHandler).to.not.have.been.called

    it 'catches blank emails', ->
      enterEmail('')
      enterPassword('hamsandstuff')
      expectFormToBeInvalid

    it 'catches blank passwords', ->
      enterEmail('ham@stuff.com')
      enterPassword('')
      expectFormToBeInvalid

    it 'validates with an email and a password', ->
      enterEmail('ham@stuff.com')
      enterPassword('hamsandstuff')
      expectFormToBeValid

    describe 'submission', ->
      it 'submits the form to submit on enter in the password input', ->
        enterEmail('ham@stuff.com')
        enterPassword('hamsandstuff')
        Test.triggerKeyPress(passwordInput, KEYCODE_ENTER)
        expectFormSubmission



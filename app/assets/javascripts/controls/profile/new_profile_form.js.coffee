#= require constants
#= require copious/plugin
#= require copious/form
#= require validation

class NewProfileForm
  constructor: (@form) ->
    @button = @form.find('button')
    @password = @form.find('[name="user[password]"]')
    validator = @form.validate(
      submitHandler: (form) =>
        # disable button on submit
        $.rails.disableFormElements($(form))
        form.submit()
      invalidHandler: (event, validator) =>
        this.invalid()
      onkeyup: (element, event) =>
        unless event.which == KEYCODE_TAB or event.which == KEYCODE_ENTER
          if validator.checkForm()
            this.valid()
          else
            this.invalid())
    @password.on 'keypress', (e) ->
      submitOnEnter(@form, e)
    this.initExternalPhoto()
    this.disableButton()

  valid: =>
    @form.trigger('newProfileForm:valid')
    this.enableButton()

  invalid: =>
    @form.trigger('newProfileForm:invalid')
    this.disableButton()

  enableButton: =>
    @button.prop('disabled', false)

  disableButton: =>
    @button.prop('disabled', true)

  facebookPhoto: (username) =>
    profile_img_url = "//graph.facebook.com/#{username}/picture?type=large"
    @form.find("img:first").attr("src", profile_img_url)

  twitterPhoto: (username) =>
    profile_img_url = "https://api.twitter.com/1/users/profile_image?screen_name=#{username}&size=bigger"
    @form.find("img:first").attr("src", profile_img_url)

  initExternalPhoto: =>
    $fbIdMeta = $("meta[name='copious:facebook-id']")
    $twitterIdMeta = $("meta[name='copious:twitter-id']")
    if $fbIdMeta.exists()
      this.facebookPhoto($fbIdMeta.attr("content"))
    else if $twitterIdMeta.exists()
      this.twitterPhoto($twitterIdMeta.attr("content"))

  setExternalPhoto: (authType, username) =>
    if authType is 'facebook'
      this.facebookPhoto(username)
    else if authType is 'twitter'
      this.twitterPhoto(username)

jQuery ->
  $.fn.newProfileForm = copious.plugin.componentPlugin(NewProfileForm, 'newProfileForm')
  $('[data-role=new-profile-form]').newProfileForm()

jQuery ->
  $fileupload = $('#user_profile_photo')
  $form = $('form.edit_user')
  updateProfilePhoto = (e, jsend) ->
    $('#profile-photo').replaceWith(jsend.result)

  # we use POST as the type–even though it's a PUT–to support older browsers.  the form in the page assigns
  # _method = 'put', which tells rails that it's actually a PUT.
  $fileupload.remoteFileupload({type: 'POST', url: $form.attr('action'), replaceFileInput: false}).
     bind 'jsend:success', updateProfilePhoto
  $.remoteForm.initRemoteForm('[data-role=refresh-photo]').bind 'jsend:success', updateProfilePhoto

  $('#user_bio').charlimit()

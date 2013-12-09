# Validator doesn't consisently validate when loading edit page.
$(window).on 'load', () ->
  if window.location.href.match('edit')
    $('#preview_listing').removeAttr('disabled').removeClass('disabled')
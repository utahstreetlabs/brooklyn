# requires bootstrap tooltips

jQuery ->
  $('[rel~=tooltip]').tooltip()
#  $(document).on 'click', 'a[rel~=tooltip]', () -> $(this).tooltip('hide')

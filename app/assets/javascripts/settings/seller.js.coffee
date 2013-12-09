jQuery ->
  $('#account_selector').on 'change', (e) =>
    $('[data-role=new-account]').hide()
    $("##{$('option:selected', this).val()}").show()

  $('[data-role=add-account]').on 'click', (e) =>
    e.preventDefault()
    $('#new-account').show()

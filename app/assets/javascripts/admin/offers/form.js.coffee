jQuery ->
  $('#collapse-new-users').on 'cc:hide', () ->
    $('#offer_signup').attr('checked', false)

  $('#collapse-existing-users').on 'cc:hide', () ->
    $('#offer_no_purchase_users').attr('checked', false)
    $('#offer_no_credit_users').attr('checked', false)

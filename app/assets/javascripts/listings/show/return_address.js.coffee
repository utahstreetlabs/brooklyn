jQuery ->
  # When saving a new return address, submit the correct form in the modal depending
  # on if a new address was populated or not.
  $newAddrName = $('#return_address_change-modal #new_address_name')
  $newAddrLine1 = $('#return_address_change-modal #new_address_line1')

  $('#return_address_change-modal form#new_address_new').on 'submit', ->
    ($newAddrName.val() != '') && ($newAddrLine1.val() != '')

  $('#return_address_change-modal form#ship_from_new').on 'submit', ->
    ($newAddrName.val() == '') && ($newAddrLine1.val() == '')

  # On successful change/update of return address, clear out new
  # address fields in modal.  Also, remove the disabled class from
  # the generate label button if it's present.
  $('#return_address_change-modal').on 'jsend:success', ->
   $(this).find("form#new_address_new")[0].reset()
   $('[data-action=generate-label].disabled').removeClass('disabled')

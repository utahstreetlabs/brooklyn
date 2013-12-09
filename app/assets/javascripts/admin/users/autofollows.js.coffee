jQuery ->
  $("[data-role='user']").on 'jsend:success', '[data-action=remove-autofollow]', (event,data) ->
    copious.bootstrapAlert.notice(data.alert) if data.alert
    $(this).parents('tr').hide()

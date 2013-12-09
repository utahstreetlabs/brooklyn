jQuery ->
  $('[data-role=approval-toolbar-button]').each ->
    $button = $(this)
    $button.on 'jsend:success', (event, data) ->
      $button.closest('[data-role=approval-toolbar]').replaceWith data.alert if data.alert
    $button.on 'jsend:fail', (event, data) ->
      $button.closest('[data-role=approval-toolbar]').replaceWith data.alert if data.alert

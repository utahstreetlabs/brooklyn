# there is absolutely a way to dry this up, but I banged my head against coffeescript for a while, and I'm sick of it.

jQuery ->
  $('[data-action=suggest-on]').each ->
    $button = $(this)
    $button.on 'jsend:success', (event, data) ->
      copious.bootstrapAlert.notice(data.alert) if data.alert
      $("[data-role='user-info']").html(data.userInfo) if data.userInfo
      $button.hide()
      $("[data-action=suggest-off]").show()
    $button.on 'jsend:fail', (event, data) ->
      copious.bootstrapAlert.alert(data.alert) if data.alert

  $('[data-action=suggest-off]').each ->
    $button = $(this)
    $button.on 'jsend:success', (event, data) ->
      copious.bootstrapAlert.notice(data.alert) if data.alert
      $("[data-role='user-info']").html(data.userInfo) if data.userInfo
      $button.hide()
      $("[data-action=suggest-on]").show()
    $button.on 'jsend:fail', (event, data) ->
      copious.bootstrapAlert.alert(data.alert) if data.alert

  $('[data-action=autofollow-on]').each ->
    $button = $(this)
    $button.on 'jsend:success', (event, data) ->
      copious.bootstrapAlert.notice(data.alert) if data.alert
      $("[data-role='user-info']").html(data.userInfo) if data.userInfo
      $button.hide()
      $("[data-action=autofollow-off]").show()
    $button.on 'jsend:fail', (event, data) ->
      copious.bootstrapAlert.alert(data.alert) if data.alert

  $('[data-action=autofollow-off]').each ->
    $button = $(this)
    $button.on 'jsend:success', (event, data) ->
      copious.bootstrapAlert.notice(data.alert) if data.alert
      $("[data-role='user-info']").html(data.userInfo) if data.userInfo
      $button.hide()
      $("[data-action=autofollow-on]").show()
    $button.on 'jsend:fail', (event, data) ->
      copious.bootstrapAlert.alert(data.alert) if data.alert

  $('[data-action=superuser-on]').each ->
    $button = $(this)
    $button.on 'jsend:success', (event, data) ->
      copious.bootstrapAlert.notice(data.alert) if data.alert
      $("[data-role='user-info']").html(data.userInfo) if data.userInfo
      $button.hide()
      $("[data-action=superuser-off]").show()
    $button.on 'jsend:fail', (event, data) ->
      copious.bootstrapAlert.alert(data.alert) if data.alert

  $('[data-action=superuser-off]').each ->
    $button = $(this)
    $button.on 'jsend:success', (event, data) ->
      copious.bootstrapAlert.notice(data.alert) if data.alert
      $("[data-role='user-info']").html(data.userInfo) if data.userInfo
      $button.hide()
      $("[data-action=superuser-on]").show()
    $button.on 'jsend:fail', (event, data) ->
      copious.bootstrapAlert.alert(data.alert) if data.alert

  $('[data-action=admin-on]').each ->
    $button = $(this)
    $button.on 'jsend:success', (event, data) ->
      copious.bootstrapAlert.notice(data.alert) if data.alert
      $("[data-role='user-info']").html(data.userInfo) if data.userInfo
      $button.hide()
      $("[data-action=admin-off]").show()
    $button.on 'jsend:fail', (event, data) ->
      copious.bootstrapAlert.alert(data.alert) if data.alert

  $('[data-action=admin-off]').each ->
    $button = $(this)
    $button.on 'jsend:success', (event, data) ->
      copious.bootstrapAlert.notice(data.alert) if data.alert
      $("[data-role='user-info']").html(data.userInfo) if data.userInfo
      $button.hide()
      $("[data-action=admin-on]").show()
    $button.on 'jsend:fail', (event, data) ->
      copious.bootstrapAlert.alert(data.alert) if data.alert
window.copious ?= {}

copious.featureEnabled = (featureFlag) ->
  $("meta[name='copious:ff:#{featureFlag}']").attr('content') is 'enabled'

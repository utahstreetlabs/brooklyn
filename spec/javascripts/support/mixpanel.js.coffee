# stub out mixpanel
# XXX: rework tracking/mixpanel so that we can reuse its stubbing behavior here

window.mixpanel = {}

for f in ['disable','track','track_pageview','track_links','track_forms','register','register_once','unregister','identify','name_tag','set_config','get_property']
  window.mixpanel[f] = ->

window.mixpanel['people'] = {}
for f in ['set','increment']
  window.mixpanel['people'][f] = ->

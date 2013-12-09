# requires tracking/mixpanel to have bootstrapped the mixpanel api

window.copious ||= {}

copious.source = (element) ->
  return element if typeof element is 'string'
  $element = if element instanceof jQuery then element else $(element)
  $element.data('source') or $element.closest('[data-source]').data('source')

copious.pageSource = () ->
  $('body').data('page-source')

copious.track = (event, properties = {}, callback = ->) ->
  properties.source = copious.source(properties.source) if properties.source?
  properties.page_source = copious.pageSource()
  mixpanel.track(event, properties, callback)

copious.track_links = (selector, event, properties = {}) ->
  mixpanel.track_links selector, event, (element) ->
    if $.isFunction(properties)
      properties = properties.call(this, element)
    properties.source = copious.source(properties.source) if properties.source?
    properties.page_source = copious.pageSource()
    properties

copious.track_forms = (selector, event, properties = {}) ->
  mixpanel.track_forms selector, event, (element) ->
    if $.isFunction(properties)
      properties = properties.call(this, element)
    properties.source = copious.source(properties.source) if properties.source?
    properties.page_source = copious.pageSource()
    properties

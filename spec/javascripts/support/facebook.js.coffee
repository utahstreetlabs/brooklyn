# bootstrap FB api
class FbEventAggregator
  callbacks = {}

  @subscribe: (name, callback) ->
    callbacks[name] ?= []
    callbacks[name].push(callback)

  @trigger: (name, response) ->
    callback(response) for callback in (callbacks[name] || [])

window.initializeFacebook = ->
  window.FB ?= {
    init: (options) ->,
    login: (callback, options) ->,
    getAuthResponse: ->,
    api: (endpoint, callback) ->,
    ui: (options, callback) ->,
    Event: FbEventAggregator
  }

  beforeEach ->
    COPIOUSFB.initialize()

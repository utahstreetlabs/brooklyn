# thanks to https://gist.github.com/2024197 for the inspiration
class MockServer
  constructor: () ->
    @server = sinon.fakeServer.create()

  respondWith: (urlOrRegExp, options = {}) ->
    type = options.type
    code = options.code ? 200
    headers = options.headers ? {}
    data = options.data ? ''

    contentType = options.contentType ? headers['Content-Type']
    contentType = 'application/x-www-form-urlencoded' if contentType is 'form'
    headers['Content-Type'] = contentType if contentType

    unless typeof data is 'string'
      contentType ?= 'application/json'
      headers['Content-Type'] = contentType
      if /json$/.test(contentType)
        data = JSON.stringify(data)
      else if /x-www-form-urlencoded$/.test(contentType)
        data = $.param(data)

    if urlOrRegExp
      if type
        @server.respondWith(type, urlOrRegExp, [code, headers, data])
      else
        @server.respondWith(urlOrRegExp, [code, headers, data])
    else
      # if urlOrRegExp is falsy, use as default response, a.k.a, when no response matches, returns this
      @server.respondWith([code, headers, data])

  respond: () =>
    @server.respond()

  tearDown: () =>
    @server.restore()

window.MockServer = MockServer

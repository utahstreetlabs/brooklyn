#= require spec_helper
#= require notifications
server = null
spy = null

describe 'Notifications', ->
  beforeEach ->
    server = new MockServer
    $('body').html(JST['templates/notifications']())

  afterEach ->
    server.tearDown()

  describe 'when clicking on a notification', ->
    beforeEach ->
      spy = sinon.stub(COPIOUSNS, "redirectWindow")

    it 'redirects the browser to the target url', ->
      $('[data-role=notification]').click()
      spy.should.have.been.called

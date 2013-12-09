#= require spec_helper
#= require controls/modal_loader

describe 'Modal loader', ->
  subject = null
  spinner = null
  alert = null
  modalContent = null
  server = null
  url = '/gimme/content'

  respondForModalWithSuccess = (response) ->
    server.respondWith(url, data: { status: 'success', data: { modal: response}})

  respondForModalWithFailure = (msg) ->
    server.respondWith(url, data: { status: 'fail', data: { status: 400, error: msg}})

  beforeEach ->
    server = new MockServer
    $('body').html(JST['templates/controls/modal_loader']())
    spinner = $('[data-role=spinner]')
    alert = $('[data-role=alert]')
    modalContent = $('[data-role=modal-content]')
    subject = new ModalLoader($('[data-role=lazy-modal]'))

  it 'loads content', ->
    respondForModalWithSuccess('Hey it loaded!')
    subject.load()
    expect(spinner).to.be.visible
    server.respond()
    expect(spinner).not.to.be.visible
    expect(modalContent).to.contain('Hey it loaded!')

  it 'displays errors content', ->
    respondForModalWithFailure('You suck.')
    subject.load()
    expect(spinner).to.be.visible
    server.respond()
    expect(spinner).not.to.be.visible
    expect(alert).to.contain('Oops')

  it 'only loads content once', ->
    respondForModalWithSuccess('Hey it loaded!')
    subject.load()
    expect(spinner).to.be.visible
    server.respond()
    expect(spinner).not.to.be.visible
    expect(modalContent).to.contain('Hey it loaded!')

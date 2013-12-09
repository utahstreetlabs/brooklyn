#= require spec_helper
#= require copious/remote_form
#= require copious/jsend
#= require controls/collections/new_collection_input
#= require constants

describe 'NewCollectionInput', ->
  subject = null

  beforeEach ->
    $('body').html(JST['templates/controls/collections/new_collection_input']())
    subject = $('[data-role=name-input]').newCollectionInput('instance')

  describe 'when a new collection is added', ->
    it 'submits the collection name on enter', ->
      spy = sinon.stub(subject, 'submitNewCollection')
      Test.triggerKeyDown('[data-role=collection-name]', KEYCODE_ENTER)
      spy.should.have.been.called

    it 'does not submit on non-enter', ->
      spy = sinon.stub(subject, 'submitNewCollection')
      Test.triggerKeyDown('[data-role=collection-name]', KEYCODE_SPACE)
      spy.should.not.have.been.called

    describe 'submitCollection', ->
      server = null

      before ->
        server = sinon.fakeServer.create()
      after ->
        server.restore()

      it 'resets the input and triggers collectionCreated', ->
        resetSpy = sinon.stub(subject, 'reset')
        data = {"name":"fark","id":"fark","dropdownMenu":"","list_item":""}
        triggerSpy = sinon.stub(subject.element, 'trigger').withArgs('newCollectionInput:created', data)
        subject.submitNewCollection()
        server.respondWith([200, {'Content-Type': 'application/json'},
                            JSON.stringify({status: 'success', data: data})])
        server.respond()
        resetSpy.should.have.been.called
        triggerSpy.should.have.been.called

      it 'displays the errors', ->
        resetSpy = sinon.stub(subject, 'reset')
        data = {errors: {name: 'Invalid'}}
        triggerSpy = sinon.stub(subject.element, 'trigger').withArgs('newCollectionInput:creationFailed', data)
        subject.submitNewCollection()
        server.respondWith([200, {'Content-Type': 'application/json'},
                            JSON.stringify({status: 'fail', data: data})])
        server.respond()
        resetSpy.should.have.been.called
        triggerSpy.should.have.been.called
        expect($('[data-role=add-collection-errors]')).to.be

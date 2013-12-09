#= require spec_helper
#= require controls/collections/multi_collection_selector

describe 'Multi collection selector spec', ->
  subject = null
  commentInput = null
  haveSelectedSpy = null
  haveUnselectedSpy = null
  wantSelectedSpy = null
  wantUnselectedSpy = null

  beforeEach ->
    $('body').html(JST['templates/controls/collections/multi_collection_selector']())
    subject = $('[data-role=multi-collection-selector]').multiCollectionSelector()

    haveSelectedSpy = sinon.spy()
    haveUnselectedSpy = sinon.spy()
    wantSelectedSpy = sinon.spy()
    wantUnselectedSpy = sinon.spy()
    subject.on 'collection:haveSelected', -> haveSelectedSpy()
    subject.on 'collection:haveUnselected', -> haveUnselectedSpy()
    subject.on 'collection:wantSelected', -> wantSelectedSpy()
    subject.on 'collection:wantUnselected', -> wantUnselectedSpy()

  describe 'events', ->
    it 'should trigger have events', ->
      $('#have').click()
      expect(haveSelectedSpy).to.have.been.called
      $('#have').click()
      expect(haveUnselectedSpy).to.have.been.called

    it 'should trigger want events', ->
      $('#want').click()
      expect(wantSelectedSpy).to.have.been.called
      $('#want').click()
      expect(wantUnselectedSpy).to.have.been.called

    it "should not trigger have or want events if have or want buttons aren't clicked", ->
      $('#other').click()
      $('#other').click()
      expect(haveSelectedSpy).not.to.have.been.called
      expect(haveUnselectedSpy).not.to.have.been.called
      expect(wantSelectedSpy).not.to.have.been.called
      expect(wantUnselectedSpy).not.to.have.been.called

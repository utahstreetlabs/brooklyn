#= require spec_helper
#= require copious/remote_form
#= require copious/jsend
#= require controls/collections/collection_dropdown
#= require constants

describe 'CollectionDropdown', ->
  subject = null

  beforeEach ->
    $('body').html(JST['templates/controls/collections/collection_dropdown']())
    subject = new CollectionDropdown($('[data-role=collections-list]'), {})

  describe '.updateAll', ->
    it 'refreshes the dropdown menu', ->
      newDropdown = "<ul data-role='dropdown-menu'><li><a href='/foo/bar'>new item</a></li></ul>"
      CollectionDropdown.updateAll(newDropdown)
      $('[data-role=dropdown-menu] li a').html().should == 'new item'

  describe '#hideUI', ->
    it 'hides an open dropdown', ->
      subject.dropdown.addClass('open')
      subject.hideUI()
      subject.dropdown.should.not.have.class('open')

  describe '#setTitle', ->
    it 'sets the dropdown title', ->
      subject.setTitle('Foo Bar', 'foo-bar')
      $('[data-role=dropdown-title]', subject.dropdown).should.have.text('Foo Bar')

  describe '#addDropdownItem', ->
    describe 'when the element does not exist', ->
      it 'adds a new list item before the divider', ->
        list_item = "<li data-collection-id=test-item><a href='/path/to/item'></a></li>"
        $('[data-collection-id=test-item]').should.not.exist
        subject.addDropdownItem('test-item', list_item)
        $('[data-collection-id=test-item]').should.exist

    describe 'when the element does exist', ->
      it 'does not add a new list item', ->
        list_item = "<li data-collection-id=things-i-have><a href='/path/to/item'></a></li>"
        $('[data-collection-id=things-i-have]').should.exist
        subject.addDropdownItem('things-i-have', list_item)
        $('[data-collection-id=things-i-have]').length.should.equal(1)

  describe 'when a dropdown item is clicked', ->
    it "updates the title", ->
      spy = sinon.stub(subject, 'setTitle').withArgs('Things I Have', 'things-i-have')
      $('[data-collection-id=things-i-have] a').click()
      spy.should.have.been.called

  describe 'collection created', ->
    it 'properly updates the dropdown', ->
      titleSpy = sinon.stub(subject, 'setTitle').withArgs('Rekkids', 'rekkids')
      addDropdownSpy = sinon.stub(subject, 'addDropdownItem').withArgs('rekkids', 'li')
      resetDropdownSpy = sinon.stub(subject, 'resetDropdown').withArgs(true)
      subject.newCollectionInput.trigger('newCollectionInput:created', {name: 'Rekkids', id: 'rekkids', list_item: 'li'})
      titleSpy.should.have.been.called
      addDropdownSpy.should.have.been.called
      resetDropdownSpy.should.have.been.called

  describe 'collection creation failed', ->
    it 'displays the errors', ->
      resetDropdownSpy = sinon.stub(subject, 'resetDropdown').withArgs(false)
      subject.newCollectionInput.trigger('newCollectionInput:creationFailed', {errors: {name: 'Invalid'}})
      resetDropdownSpy.should.have.been.called
      expect($('[data-role=add-collection-errors]')).to.be

  describe 'dropdown refresh', ->
    it 'successfully updates the dropdown', ->
      spy = sinon.stub(CollectionDropdown, 'updateAll').withArgs('foo')
      $(document).trigger('collectionDropdown:refresh', 'foo')
      spy.should.have.been.called

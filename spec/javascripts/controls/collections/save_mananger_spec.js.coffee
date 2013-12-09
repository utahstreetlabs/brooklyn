#= require spec_helper
#= require copious/remote_form
#= require copious/jsend
#= require controls/collections/save_manager
#= require constants

describe 'Save manager', ->
  subject = null
  commentInput = null

  beforeEach ->
    $('body').html(JST['templates/controls/collections/save_manager']())
    server = new MockServer
    server.respondWith('/save_modal', data: {status: 'success', data: {modal: JST['templates/controls/collections/save_manager_content']()}})
    subject = $('[data-role=save-manager]').modal('show')
    server.respond()
    commentInput = $('[data-role=comment]', subject)

  describe 'form submission', ->
    successSpy = sinon.spy()

    beforeEach ->
      subject.find('form').on 'submit', ->
        subject.trigger('jsend:success', {saveButton: '<div></div>'})
        false
      subject.on 'jsend:success', ->
        successSpy()

    it 'submits when enter is pressed', ->
      Test.triggerKeyPress('[data-role=save-manager] [name=comment]', Test.Keys.ENTER)
      expect(successSpy).to.have.been.called

    it 'clears the comment box after submission', ->
      commentInput.val("This is a sample comment")
      subject.find('form').submit()
      expect(successSpy).to.have.been.called
      commentInput.val().should.be.empty

  it 'triggers collection success when success modal hidden', ->
    spy = sinon.stub()
    $(document).on 'saveManager:succeeded', ->
      spy()
    $('[data-role=save-manager-success-modal]').trigger 'hidden', {}
    spy.should.have.been.called

  describe 'when "Things That Are Awesome" is selected', ->
    beforeEach ->
      $('[data-role=save-manager] [data-collection-id=things-that-are-awesome]').click()

    it 'hides the have checkbox', ->
      expect($('[data-role=save-manager] [data-role=have]')).to.be.hidden

    it 'unchecks the have checkbox', ->
      expect($('[data-role=save-manager] [data-role=have]')).to.not.be.checked

    it 'unchecks the want checkbox', ->
      expect($('[data-role=save-manager] [data-role=want]')).to.not.be.checked

  describe 'when "Things I Have" is selected', ->
    beforeEach ->
      $('[data-role=dropdown-menu] [data-collection-id=things-i-have] a').click()

    it 'shows the have checkbox', ->
      expect($('[data-role=save-manager] [data-role=have]')).to.be.visible

    it 'checks the have checkbox', ->
      expect($('[data-role=save-manager] [data-role=have] input[type=checkbox]')).to.be.checked

    it 'unchecks the want checkbox', ->
      expect($('[data-role=save-manager] [data-role=want]')).to.not.be.checked

  describe 'when "Things I Want" is selected', ->
    beforeEach ->
      $('[data-role=dropdown-menu] [data-collection-id=things-i-want] a').click()

    it 'hides the have checkbox', ->
      expect($('[data-role=save-manager] [data-role=have]')).to.be.hidden

    it 'checks the want checkbox', ->
      expect($('[data-role=save-manager] [data-role=want] input[type=checkbox]')).to.be.checked

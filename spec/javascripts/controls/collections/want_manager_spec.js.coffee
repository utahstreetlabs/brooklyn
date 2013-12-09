#= require spec_helper
#= require controls/remote_modal
#= require controls/collections/want_manager

describe 'collections.WantManager', ->
  subject = null
  successSpy = null

  beforeEach ->
    $('body').html(JST['templates/controls/collections/want_modal']())
    subject = $('[data-role=want-modal]').modal('show')
    successSpy = sinon.spy()
    subject.on 'jsend:success', ->
      successSpy()

  afterEach ->
    expect(successSpy).to.have.been.called

  describe 'when submitting the the want modal', ->
    beforeEach ->
      subject.find('form').on 'submit', ->
        subject.trigger('jsend:success', {followupModal: "<div data-role='save-manager-success-modal'></div>"})
        false
      $('[data-role=want-modal] [data-save=modal]').click()
      subject.trigger('ajax:complete', {})

    it "hides the modal", ->
      expect($('[data-role=want-modal]')).to.be.hidden

    it 'displays the success modal', ->
      expect($('[data-role=save-manager-success-modal]')).to.be.visible

  describe 'skipping submission of a want', ->
    beforeEach ->
      $('[data-role=want-modal]').on 'click', ->
        subject.trigger('jsend:success', {followupModal: "<div data-role='save-manager-success-modal'></div>"})
        false

    describe 'when clicking the skip button', ->
      beforeEach ->
        $('[data-role=want-modal] [data-action=want-skip]').click()
        subject.trigger('ajax:complete', {})

      it "hides the modal", ->
        expect($('[data-role=want-modal]')).to.be.hidden

      it 'displays the success modal', ->
        expect($('[data-role=save-manager-success-modal]')).to.be.visible

    describe 'when clicking the close modal button', ->
      beforeEach ->
        $('[data-role=want-modal] [data-dismiss=modal]').click()
        subject.trigger('ajax:complete', {})

      it "hides the modal", ->
        expect($('[data-role=want-modal]')).to.be.hidden

      it 'displays the success modal', ->
        expect($('[data-role=save-manager-success-modal]')).to.be.visible

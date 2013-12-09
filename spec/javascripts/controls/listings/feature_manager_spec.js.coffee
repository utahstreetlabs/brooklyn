#= require spec_helper
#= require controls/listings/feature_manager
#= require controls/multi_selector
#= require controls/remote_modal
#= require copious/remote_form

describe 'listings.FeatureManager', ->
  server = null
  subject = null
  successSpy = null
  failSpy = null

  respondForModalWithSuccess = ->
    server.respondWith(/\/listings\/hamburgler-doll\/features\/feature_modal/, data: {status: 'success', data:
                      { modal: """
<div data-role='modal-content'>
  <div class='product-image-container'>
    <img class='product-image' title='hamburgler-doll' src='//example.com/hamburger_doll.jpg'>
  </div>
  <form id='listing-feature-123-form' method='post' data-role='listing-feature-form' data-remote='true' action='/listings/hamburgler-doll/features'>
    <div>
      <input type='hidden' value='put' name='_method'>
    </div>
    <div class='multi-selector' data-role='selectables'>
      <label class='checkbox'>
        <input id='category_id' type='checkbox' value='10' name='category_id'>
          Accessories
      </label>
      <label class='checkbox'>
        <input id='tag_ids_' type='checkbox' value='110' name='tag_ids[]'>
          animated
      </label>
    </div>
  </form>
</div>"""}})

  respondForModalWithFailure = ->
    server.respondWith(/\/listings\/hamburgler-doll\/features\/feature_modal/, data: {status: 'fail', data: {
                       status: 400, error: 'You suck'}})

  beforeEach ->
    $('body').html(JST['templates/controls/listings/feature_manager']())
    server = new MockServer

  afterEach ->
    server.tearDown()

  describe 'clicking on the toggle', ->
    beforeEach ->
      $('[data-toggle=modal]').click()

    it 'instantiates a FeatureManager', ->
      expect($('#listing-feature-123-modal').data('featureManager')).to.be

    it 'loads the content successfully', ->
      respondForModalWithSuccess()
      server.respond()
      expect($('#listing-feature-123-modal')).to.contain('Accessories')

    it 'shows an error when loading the content fails', ->
      respondForModalWithFailure()
      server.respond()
      expect($('[data-role=alert]')).to.contain('Oops')

    describe 'and selecting a feature', ->
      beforeEach ->
        $('[data-toggle=modal]').click()
        respondForModalWithSuccess()
        server.respond()
        subject = $('[data-role=feature-manager]').modal()
        successSpy = sinon.spy()
        failSpy = sinon.spy()
        subject.on 'jsend:success', ->
          successSpy()
        subject.on 'jsend:fail', ->
          failSpy()

      describe 'handles it successfully', ->
        beforeEach ->
          subject.find('form').on 'submit', ->
            subject.trigger('jsend:success', {followupModal: "<div data-role='feature-listing-123-success-modal'></div>"})
            false

        afterEach ->
          expect(successSpy).to.have.been.called

        it "for a category", ->
          $('#category_id').click()
          $('[data-save=modal]').click()

        it "for a tag", ->
          $('#tag_ids_').click()
          $('[data-save=modal]').click()

      describe 'handles a failure', ->
        beforeEach ->
          subject.find('form').on 'submit', ->
            subject.trigger('jsend:fail', {data: { status: 400, error: 'You suck'}})

        afterEach ->
          expect(failSpy).to.have.been.called

        it "for a category", ->
          $('#category_id').click()
          $('[data-save=modal]').click()

        it "for a tag", ->
          $('#tag_ids_').click()
          $('[data-save=modal]').click()
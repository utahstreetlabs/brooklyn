#= require spec_helper
#= require copious/remote_form
#= require copious/jsend
#= require controls/collections/collection_modal
#= require constants

describe 'CollectionModal', ->
  subject = null

  beforeEach ->
    $('body').html(JST['templates/controls/collections/collection_modal']())
    subject = new CollectionModal($('[data-role=save-manager]'), selector: $('<div></div>'))

  describe 'have', ->
    describe 'collection:haveSelected', ->
      it 'shows the box', ->
        subject.collectionSelector.trigger('collection:haveSelected')
        $('[data-role=have]').should.be.visible
        $('[data-role=have] input[type=checkbox]').should.be.checked
    describe 'collection:haveUnselected', ->
      it 'hides the box', ->
        subject.collectionSelector.trigger('collection:haveUnselected')
        $('[data-role=have]').should.not.be.visible
        $('[data-role=have] input[type=checkbox]').should.not.be.checked

  describe 'want', ->
    describe 'collection:wantSelected', ->
      it 'shows the box', ->
        subject.collectionSelector.trigger('collection:wantSelected')
        $('[data-role=want] input[type=checkbox]').should.be.checked
    describe 'collection:wantUnselected', ->
      it 'hides the box', ->
        subject.collectionSelector.trigger('collection:wantUnselected')
        $('[data-role=want] input[type=checkbox]').should.not.be.checked

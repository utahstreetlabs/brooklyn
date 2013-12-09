#= require spec_helper
#= require controls/tutorial_bar

describe 'Tutorial bar', ->
  beforeEach ->
    $('body').html(JST['templates/controls/tutorial_bar']())

  describe 'commenting on a listing', ->
    beforeEach ->
      $('#listing').trigger 'listing:commented', [{foo: 'bar'}]

    it 'completes the comment step', ->
      expect($('[data-tutorial-action=comment]')).to.have.class('complete')

    it 'removes the suggestion from the comment step', ->
      expect($('[data-tutorial-action=comment]')).to.not.have.class('suggestion')

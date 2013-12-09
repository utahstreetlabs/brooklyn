#= require spec_helper
#= require controls/flash

describe 'copious.flash', ->
  beforeEach ->
    $('body').html(JST['templates/controls/flash']())

  describe 'updating the flash', ->
    it 'updates the flash notice', (done) ->
      copious.flash.notice('hams')
      expect($('[data-role=flash-notice]')).to.contain('hams')
      copious.flash.clear()
      setTimeout(->
        expect($('[data-role=flash-notice]')).not.to.contain('hams')
        done()
      , 350)

    it 'updates the flash alert', (done) ->
      copious.flash.alert('ducks')
      expect($('[data-role=flash-alert]')).to.contain('ducks')
      copious.flash.clear()
      setTimeout(->
        expect($('[data-role=flash-alert]')).not.to.contain('ducks')
        done()
      , 350)

    it 'updates a custom flash', (done) ->
      copious.flash.alert('water fowl', 'water-fowl')
      expect($('#water-fowl')).to.contain('water fowl')
      copious.flash.clear('water-fowl')
      setTimeout(->
        expect($('#water-fowl')).not.to.contain('water fowl')
        done()
      , 350)

  describe 'clearing the flash', ->
    it 'clears all flashes', (done) ->
      copious.flash.notice('hams')
      copious.flash.alert('ducks')
      expect($('.messages').text()).to.contain('hams')
      expect($('.messages').text()).to.contain('ducks')
      copious.flash.clear()
      setTimeout(->
        expect($('.messages').text()).not.to.contain('hams')
        expect($('.messages').text()).not.to.contain('ducks')
        done()
      , 350)


  describe 'updating the bootstrap alert directly', ->
    it "blows away all of the alert content in a way that flash functions don't", ->
      copious.flash.info('hams')
      expect($('[data-role=alert-info]').text()).to.contain('Info:\n    \n    hams')
      copious.bootstrapAlert.info('pigs')
      expect($('[data-role=alert-info]').text()).to.contain('pigs')
      expect($('[data-role=alert-info]').text()).not.to.contain('hams')

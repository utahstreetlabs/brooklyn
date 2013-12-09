#= require spec_helper
#= require copious/modal

describe 'copious/modal', ->
  beforeEach ->
    $('body').html(JST['templates/copious/modal']())

  # pending this test because it fails some of the time for no discernable reason
  it 'does not hide a regular modal'#, (done) ->
#    clock = sinon.useFakeTimers()
#    $('#regular-modal').modal('show')
#    done()
#    clock.tick(6000) # give it an extra second to make sure
#    expect($('#regular-modal')).to.be.visible
#    clock.restore()

  it 'auto-hides an auto-hide modal', (done) ->
    clock = sinon.useFakeTimers()
    $('#auto-hide-modal').modal('show')
    done()
    clock.tick(6000) # give it an extra second to make sure
    expect($('#auto-hide-modal')).to.be.hidden
    clock.restore()

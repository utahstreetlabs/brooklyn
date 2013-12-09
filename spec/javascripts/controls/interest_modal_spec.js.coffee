#= require spec_helper
#= require controls/interest_modal
#= require controls/modal_loader

describe 'Interest modal', ->
  server = null
  subject = null
  $interestModal = null
  $counter = null

  beforeEach ->
    $('body').html(JST['templates/controls/invite_modal']())
    $interestModal = $('[data-role=interest-modal]')
    $counter = $interestModal.find('[data-role=counter]')
    subject = $interestModal.interestModal('instance')

  it 'updates the counter from like and unlike events', ->
    $interestModal.trigger('interestCard:liked', {interestsRemaining: 7})
    expect($counter.text()).to.contain(7)

  it 'enables the save button when 0 more interests are needed', ->
    $saveButton = $interestModal.find('[data-save=modal]')
    expect($saveButton.prop('disabled')).to.be.true
    $interestModal.trigger('interestCard:liked', {interestsRemaining: 1})
    expect($saveButton.prop('disabled')).to.be.true
    $interestModal.trigger('interestCard:liked', {interestsRemaining: 0})
    expect($saveButton.prop('disabled')).to.be.false

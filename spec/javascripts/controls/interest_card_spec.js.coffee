#= require spec_helper
#= require controls/interest_card

describe 'Interest card', ->
  $interestCard = null
  $interestLink = null
  subject = null
  server = null

  beforeEach ->
    $('body').html(JST['templates/controls/invite_card']())
    server = new MockServer
    $interestCard = $('[data-role=interest-card]')
    $interestLink = $interestCard.find('[data-toggle=interest-like]')
    subject = $interestCard.interestCard('instance')

  respondToLikeWithSuccess = ->
    server.respondWith('/like', data: {status: 'success', data: { button: '<span>fake button</span>', liked: true}})


  it 'adds "liked" to classes and updates the button from the response data', ->
    expect($interestCard).to.not.have.class('liked')
    respondToLikeWithSuccess()
    $interestLink.click()
    server.respond()
    expect($interestCard.text()).to.contain('fake button')
    expect($interestCard).to.have.class('liked')

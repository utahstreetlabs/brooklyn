#= require spec_helper
#= require controls/listings/love_button

describe 'listings.LoveButton', ->
  server = null

  # use regexps to account for the source and page_source params in the query string

  respondWithSuccess = ->
    server.respondWith(/\/listings\/test-bag\/like/, data: {status: 'success', data:
                      { listingId: 123, button: """
<button class="btn curatorial actioned" data-action="unlove" data-method="delete" data-target="/listings/test-bag/unlike" data-toggle="love" name="button" type="button">Loved</button>"""}})

  beforeEach ->
    $('body').html(JST['templates/controls/listings/love_button']())
    server = new MockServer

  afterEach ->
    server.tearDown()

  describe 'clicking the love button on the first test-bag card', ->
    beforeEach ->
      $('#listing-card-1 [data-action=love]').click()
      respondWithSuccess()

    it 'updates the love button for the first test-bag card', ->
      server.respond()
      expect($('#listing-card-1 [data-action=unlove]')).to.contain('Loved')

    it 'rebinds the love button for the first test-bag card', ->
      server.respond()
      expect($('#listing-card-1 [data-listing=123]').data('love-button').method).to.equal('delete')

    it 'updates the love button for the second test-bag card', ->
      server.respond()
      expect($('#listing-card-2 [data-action=unlove]')).to.contain('Loved')

    it 'rebinds the love button for the second test-bag card', ->
      server.respond()
      expect($('#listing-card-2 [data-listing=123]').data('love-button').method).to.equal('delete')

    it 'does not update the love button for the wild-party card', ->
      server.respond()
      expect($('#listing-card-3 [data-action=love]')).to.contain('Love')

    it 'does not initialize the love button for the wild-party card', ->
      server.respond()
      expect($('#listing-card-3 [data-listing=456]').data('love-button')).to.be.undefined

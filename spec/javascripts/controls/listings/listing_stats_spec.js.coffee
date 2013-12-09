#= require spec_helper
#= require controls/listings/listing_stats

describe 'listings.ListingStats', ->
  text = 'Loves 23 | Saves 5'
  html = """<span id="listing-stats" data-role="listing-stats">#{text}</span>"""

  beforeEach ->
    $('body').html(JST['templates/controls/listings/listing_stats']())

  describe 'on listingStats:replaced', ->
    beforeEach ->
      $(document).trigger('listingStats:replaced', [123, html])

    it 'updates the listing stats html', (done) ->
      done()
      expect($('#listing-stats')).to.contain(text)

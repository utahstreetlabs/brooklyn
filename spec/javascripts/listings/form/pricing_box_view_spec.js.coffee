#= require spec_helper
#= require listings/form/pricing_box

describe 'listings/form/pricing_box_view', ->
  subject = null

  beforeEach ->
    $('body').html(JST['templates/listings/form/pricing_box_view']())
    subject = new PricingBoxView

  describe '#initialize', ->
    it 'sets the hide shipping flag', ->
      subject.hideShipping.should.equal(true)
    it 'sets the model price', ->
      subject.model.get('price').should.equal(10.00)
    it 'sets the model shipping price', ->
      subject.model.get('shipping').should.equal(1.00)
    it 'sets the model fee rate', ->
      subject.model.get('feeRate').should.equal(0.06)
    it 'sets the model seller pays marketplace fee flag', ->
      subject.model.get('sellerPaysMarketplaceFee').should.equal(true)

  describe '#updatePrice', (done) ->
    it 'updates the modal and view', (done) ->
      $('#listing_price').val('15.00').change()
      done()
      subject.model.get('price').should.equal(15.00)
      subject.model.get('cost').should.equal(16.00)
      $('[data-role=price]').should.have.text('$15.00')
      $('[data-role=cost]').should.have.text('$16.00')

  describe '#updateShipping', (done) ->
    beforeEach ->
      subject.hideShipping = false

    it 'updates the modal and view', (done) ->
      $('#listing_shipping').val('0.00').change()
      done()
      subject.model.get('shipping').should.equal(0.00)
      subject.model.get('cost').should.equal(10.00)
      $('[data-role=shipping]').should.have.text('$0.00')
      $('[data-role=cost]').should.have.text('$10.00')

  describe '#updateSellerPaysMarketplaceFee', (done) ->
    it 'updates the modal and view', (done) ->
      $('#listing_seller_pays_marketplace_fee').removeProp('checked').change()
      done()
      subject.model.get('sellerPaysMarketplaceFee').should.equal(false)
      subject.model.get('cost').should.equal(11.66)
      $('[data-role=marketplace-fee]').should.have.text('$0.66')
      $('[data-role=cost]').should.have.text('$11.66')

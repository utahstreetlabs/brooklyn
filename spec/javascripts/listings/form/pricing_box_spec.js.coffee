#= require spec_helper
#= require listings/form/pricing_box

describe 'listings/form/pricing_box', ->
  subject = null

  beforeEach ->
    subject = new PricingBox {
      price: 10,
      shipping: 1,
      feeRate: 0.06,
      sellerPaysMarketplaceFee: false
    }

  describe '#initialize', ->
    it 'sets cost', ->
      subject.get('cost').should.equal(11.66)

  describe 'change:price', ->
    beforeEach -> subject.set('price', 20)

    describe 'when seller pays marketplace fee', ->
      beforeEach -> subject.set('sellerPaysMarketplaceFee', true)

      it 'updates cost without marketplace fee', ->
        subject.get('cost').should.equal(21.00)

    describe 'when buyer pays marketplace fee', ->
      it 'updates cost including marketplace fee', ->
        subject.get('cost').should.equal(22.26)

  describe 'change:shipping', ->
    beforeEach -> subject.set('shipping', 2)

    it 'updates cost including shipping', ->
      subject.get('cost').should.equal(12.72)

  describe 'change:sellerPaysMarketplaceFee', ->
    describe 'when seller now pays marketplace fee', ->
      beforeEach -> subject.set('sellerPaysMarketplaceFee', true)

      it 'updates cost without marketplace fee', ->
        subject.get('cost').should.equal(11.00)

    describe 'when buyer now pays marketplace fee', ->
      beforeEach -> subject.set('sellerPaysMarketplaceFee', false)

      it 'updates cost with marketplace fee', ->
        subject.get('cost').should.equal(11.66)

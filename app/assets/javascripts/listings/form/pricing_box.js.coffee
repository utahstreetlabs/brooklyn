#= require 'listings/form/pricing_box_template'

jQuery ->
  Handlebars.registerHelper 'currency', (amount) ->
    if amount != undefined
      amount.toFixed(2)

  class PricingBox extends Backbone.Model
    defaults:
      price: 0
      shipping: 0
      feeRate: 0
      sellerPaysMarketplaceFee: false
      cost: 0

    initialize: =>
      this.updateCost()
      this.on 'change', this.updateCost

    updateCost: =>
      amount = this.subtotal()
      amount += this.marketplaceFee(amount)
#      debug.log "updating cost to #{amount}"
      this.set('cost', amount)

    subtotal: =>
      this.get('price') + this.get('shipping')

    marketplaceFee: (basis) =>
      if this.get('sellerPaysMarketplaceFee')
        0
      else
        basis * this.get('feeRate')

    toJSON: =>
      attrs = super
      attrs.subtotal = this.subtotal()
      attrs.marketplaceFee = this.marketplaceFee(attrs.subtotal)
      attrs.shipping = this.get('shipping')
      attrs

  # XXX: use https://github.com/theironcook/Backbone.ModelBinder or Backbone-Marionette or something
  # similar, so that we don't have to explicitly delegate events, initialize model attributes or re-render the entire
  # box when a single attribute changes
  class PricingBoxView extends Backbone.View
    el:                               '#buyer-price-details'
    priceSelector:                    '#listing_price'
    shippingSelector:                 '#listing_shipping'
    sellerPaysMarketplaceFeeSelector: '#listing_seller_pays_marketplace_fee'
    hideShipping:                     false

    # XXX: wanted to use backbone's view event delegation via @events, but the events weren't firing for some reason
    initialize: =>
      _.bindAll this

      @hideShipping = @$el.data('hide-shipping')

      @model ||= new PricingBox({
        price: this.toFloat($(@priceSelector).val())
        shipping: this.toFloat($(@shippingSelector).val())
        feeRate: this.toFloat(@$el.data('fee-rate'))
        sellerPaysMarketplaceFee: $(@sellerPaysMarketplaceFeeSelector).is(":checked")
      })
      @model.on 'change', this.render

      $(@priceSelector).on 'change', (event) =>
        this.updatePrice(this.toFloat($(event.target).val()))
      $(@shippingSelector).on 'change', (event) =>
        this.updateShipping(this.toFloat($(event.target).val()))
      $(@sellerPaysMarketplaceFeeSelector).on 'change', (event) =>
        this.updateSellerPaysMarketplaceFee($(event.target).is(":checked"))

    updatePrice: (amount)                  => @model.set('price',                    this.toFloat(amount))
    updateShipping: (amount)               => @model.set('shipping',                 this.toFloat(amount))
    updateSellerPaysMarketplaceFee: (flag) => @model.set('sellerPaysMarketplaceFee', flag)

    render: =>
      data = @model.toJSON()
      data.hideShipping = @hideShipping
#      debug.log "json: #{JSON.stringify data}"
      @$el.html HandlebarsTemplates['listings/form/pricing_box_template'](data)

    toFloat: (val) =>
      n = Math.abs parseFloat(val)
      if isNaN(n) then 0 else n

  # override Backbone.sync since we're not making any calls to the server when we change the model
  Backbone.sync = (method, model, success, error) -> success()

  # XXX: use some form of modularity, perhaps a Backbone-Marionette app or something, to make the classes visible
  # outside this source file
  window.PricingBox = PricingBox
  window.PricingBoxView = PricingBoxView

  window.pricingBoxView = new PricingBoxView
  window.pricingBox = window.pricingBoxView.model
  window.pricingBoxView.render()

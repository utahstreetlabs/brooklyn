require 'brooklyn/carrier'

module CarrierHelper
  def carrier_selector
    options = Brooklyn::Carrier.available
    if options.count == 1
      out = []
      out << hidden_field_tag('shipment[carrier_name]', options.first.key)
      out << text_field(:order, :carrier_text, disabled: true, value: options.first.name)
      out.join.html_safe
    else
      opts = {}
      opts[:selected] = params['shipment']['carrier_name'] if params['shipment']
      collection_select('shipment', 'carrier_name', options, 'key', 'name', opts)
    end
  end

  def carrier_list_string
    Brooklyn::Carrier.available.map(&:name).
      to_sentence(two_words_connector: ' or ', last_word_connector: ', or ')
  end

  def carrier_links
    Brooklyn::Carrier.available.map do |carrier|
      "#{carrier.name}: #{link_to carrier.url, carrier.url}<br />"
    end.join.html_safe
  end

  def usps_tracking_form_url
    "https://tools.usps.com/go/TrackConfirmAction_input"
  end

  def usps_tracking_url(order)
    "#{usps_tracking_form_url}?strOrigTrackNum=#{order.tracking_number}"
  end

  def usps_tracking_form(order)
    out = <<-HTML
      <form action="#{usps_tracking_form_url}" method="GET" target="_new">
        <input type="hidden" name="strOrigTrackNum" value="#{order.tracking_number}" />
        <div class="buttons">
          <button class="positive" type="submit">Track</button>
        </div>
      </form>
    HTML
    out.html_safe
  end

  def ups_tracking_url(order = nil)
    "http://wwwapps.ups.com/ietracking/tracking.cgi?tracknum=#{order.tracking_number}"
  end

  def ups_tracking_form_url
    'http://www.ups.com/WebTracking/track'
  end

  def ups_tracking_form(order)
    out = <<-HTML
      <form action="#{ups_tracking_form_url}" method="POST" target="_new">
        <input type="hidden" name="trackNums" value="#{order.tracking_number}" />
        <input type="hidden" name="loc" value="en_US" />
        <input type="hidden" name="HTMLVersion" value="5.0" />
        <input type="hidden" name="saveNumbers" value="null" />
        <input type="hidden" name="track.x" value="Track" />
        <div class="buttons">
          <button class="button" type="submit">Track</button>
        </div>
      </form>
    HTML
    out.html_safe
  end

  def tracking_url(order)
    self.send("#{order.shipping_carrier.key}_tracking_url", order)
  end

  def tracking_form(order)
    self.send("#{order.shipping_carrier.key}_tracking_form", order)
  end
end

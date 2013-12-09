module Brooklyn
 module ShippingLabels
    class ShippingLabelException < StandardError; end
    class UnsupportedShippingOption < ShippingLabelException; end
    class InvalidToAddress < ShippingLabelException; end
  end
end

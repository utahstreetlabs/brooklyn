module Listings
  module PrepaidShippingHelper
    def link_to_change_return_address(text)
      link_to(text, nilhref)
    end

    def link_to_choose_return_address(text)
      link_to(text, nilhref)
    end

    def link_to_download_shipping_label(text, listing, options = {})
      link_to(text, listing_shipping_label_path(listing), :class => 'button pull-right large',
              data: {action: 'download-label', :'disable-with' => t('.instructions.step1.download.button.disabled')})
    end

    def link_to_generate_shipping_label(text, listing, options = {})
      button_class = 'button pull-right large'
      button_class << ' disabled' if options.delete(:disabled)
      options.merge!(method: :post, :class => button_class,
        data: {action: 'generate-label', :'disable-with' => t('.instructions.step1.generate.button.disabled')})
      link_to(text, listing_shipping_label_path(listing), options)
    end

    def link_to_shipping_estimator(text)
      link_to(text, 'http://shipgooder.com/', target: '_blank', :class => 'external-link')
    end
  end
end

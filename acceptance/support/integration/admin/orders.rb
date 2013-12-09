module Admin
  module OrdersIntegrationHelpers
    shared_context "order admin" do

      # CANCEL

      def cancel_order(order)
        if order.past_checkout?
          open_modal(:cancel)
          save_modal(:cancel)
          wait_a_sec_for_selenium
        else
          cancel_button.click
          if Capybara.current_driver == Capybara.javascript_driver
            accept_alert
          end
        end
      end

      def order_should_not_be_cancellable
        # this expectation is usually the result of an ajax call that removes buttons, so retry a few times
        # to give it some time
        retry_expectations do
          cancel_button.should be_nil
          cancel_modal_button.should be_nil
        end
      end

      def cancel_button
        find('[data-action=cancel]')
      rescue Capybara::ElementNotFound
        nil
      end

      def cancel_modal_button
        find('#cancel-modal')
      rescue Capybara::ElementNotFound
        nil
      end

      # UPDATE SHIPMENT

      def update_shipment(tracking_number, options = {})
        open_modal(:update_shipment)
        disable_tracking_validation if options[:disable_tracking_validation]
        within_modal(:update_shipment) do
          fill_in 'shipment_tracking_number', with: tracking_number
        end
        save_modal(:update_shipment)
        wait_for(2)
      end

      def shipment_should_be_updated(new_tracking_number)
        find('[data-role=tracking_number]').text.strip.should == new_tracking_number
      end

      def shipment_should_not_be_updated(old_tracking_number)
        find('[data-role=tracking_number]').text.strip.should == old_tracking_number
      end

      def shipment_should_not_be_updatable
        update_shipment_button.should be_nil
      end

      def update_shipment_button
        find("[data-target='#update_shipment-modal']")
      rescue Capybara::ElementNotFound
        nil
      end

      def disable_tracking_validation
        check "Skip tracking validation"
      end

      def should_be_on_order_details_page
        current_path.should == admin_order_path(order.id)
      end
    end
  end
end

RSpec.configure do |config|
  config.include Admin::OrdersIntegrationHelpers
end

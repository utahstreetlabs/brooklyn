module ResponseBuilders
  module Orders
    class Base < ::ResponseBuilders::Base
      attr_reader :order, :user

      def initialize(options = {})
        super(options)
        @order = options[:order]
        @user = options[:user]
      end

      def user_role
        order.listing.sold_by?(user) ? :seller : :buyer
      end

      def build_failure(options = {})
        data = {:errors => order.errors.to_hash.merge(order.shipment.errors.to_hash)}
        data[:message] = options[:message] if options[:message]
        data
      end
    end
  end
end

module Brooklyn
  class PricingScheme
    cattr_accessor :default_version
    @@default_version = 1

    cattr_accessor :current_version
    @@current_version = 3

    attr_reader :buyer_fee_fixed, :buyer_fee_variable, :seller_fee_fixed, :seller_fee_variable
    def initialize(options = {})
      @buyer_fee_fixed = (options[:buyer_fee_fixed] || 0.00).to_d
      @buyer_fee_variable = (options[:buyer_fee_variable] || 0.00).to_d
      @seller_fee_fixed = (options[:seller_fee_fixed] || 0.00).to_d
      @seller_fee_variable = (options[:seller_fee_variable] || 0.00).to_d
    end

    class << self
      def configure(config)
        @schemes = config.inject([]) do |list,struct|
          list[struct.version] = self.new(struct.marshal_dump.reject { |k,v| k == :version })
          list
        end
      end

      def for_version(version)
        @schemes[version]
      end
    end
  end
end

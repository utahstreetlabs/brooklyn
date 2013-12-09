module ResponseBuilders
  module Orders
    def self.create(source, user, order, renderer)
      options = {:user => user, :order => order, :renderer => renderer}
      case (source || '').to_sym
      when :dashboard then ResponseBuilders::Orders::Dashboard.new(options)
      when :listing then ResponseBuilders::Orders::Listing.new(options)
      else raise ArgumentError.new("Unsupported order response builder source '#{source}'")
      end
    end
  end
end

module ResponseBuilders
  class Base
    attr_reader :renderer

    def initialize(options = {})
      @renderer = options[:renderer]
    end
  end
end

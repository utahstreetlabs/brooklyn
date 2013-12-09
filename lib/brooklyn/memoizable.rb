module Brooklyn
  module Memoizable
    include ActiveSupport::Concern
    include ActiveSupport::Memoizable

    alias_method :as_memoize, :memoize

    def memoize(*symbols)
      begin
        as_memoize(*symbols)
      rescue RuntimeError => e
        raise unless e.message =~ /Already memoized/
      end
    end
  end
end

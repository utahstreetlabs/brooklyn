module Brooklyn
  module Observer
    # override the +ActiveMethod::Observer+ base implementation (inherited via +ActiveRecord::Observer+) to allow
    # variable args in observer methods
    # see +Brooklyn::Observable+ for the other half (+notify_observers+)
    def update(observed_method, object, *args, &block)
      return unless respond_to?(observed_method)
      return if disabled_for?(object)
      send(observed_method, object, *args, &block)
    end
  end
end

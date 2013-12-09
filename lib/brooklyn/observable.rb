module Brooklyn
  # the +ActiveModel+ implementation of +notify_observers+ takes variable arguments but no block
  # while +ActiveModel::Observer.update+ takes fixed (2) args and a block. W.T.F.?
  # see +ObserverBase+ for our +update+ override
  # NB: models that are not descendents of +ActiveRecord::Base+ must first include +ActiveModel::Observing+
  # which is not included here to avoid conflicts in active record models.
  module Observable
    extend ActiveSupport::Concern

    module ClassMethods
      def notify_observers(method, object, *args, &block)
        observer_instances.each {|o| o.update(method, object, *args, &block)}
      end
    end

    def notify_observers(method, *args, &block)
      self.class.notify_observers(method, self, *args, &block)
    end
  end
end

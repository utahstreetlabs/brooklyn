module Controllers
  # Provides common behaviors for controllers that perform sortable queries.
  module Sortable
    def self.included(base)
      base.extend(ClassMethods)
      base.class_eval <<-EOT
        helper_method :sort_order, :sort_direction
      EOT
    end

    def sort_order
      params[:sort]
    end

    def sort_direction
      params[:direction] || :asc.to_s
    end

    module ClassMethods
    end
  end
end

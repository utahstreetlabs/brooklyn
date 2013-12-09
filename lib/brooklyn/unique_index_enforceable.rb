module Brooklyn
  module UniqueIndexEnforceable
    extend ActiveSupport::Concern

    included do
      class_eval <<-EOT
        around_save :handle_duplicate_exceptions
      EOT
    end

    module ClassMethods
      def indexes
        @indexes ||= {}
      end

      # by default, indexes will be assumed to use rails naming convention, but if the name is set differently, use
      # this method to manually create a field mapping
      def has_unique_index(name, *fields)
        indexes[name] = fields
      end
    end

    module InstanceMethods
      def handle_duplicate_exceptions(&block)
        begin
          block.call
        rescue ActiveRecord::RecordNotUnique => e
          # XXX: a bit dicey to do this on messages as I think the message comes out of mysql.
          # hopefully we keep stage and prod mysql versions in sync
          if e.message =~ /for key '(index(?:[a-z_]+_on)?_([a-z_]+))'/
            logger.warn("Handling unique index constraint violation for #{self.class} #{self.id}: #{e.message}")
            fields = self.class.indexes[$1.to_sym] || $2.split('_and_').map {|f| f.end_with?('_id') ? f[0..-4] : f }
            fields.each do |field|
              errors.add(field.to_sym, :taken)
            end
          else
            # something is wrong if we can't find a unique index that caused this error, so fallback to raising alarms
            raise
          end
        end
      end
    end
  end
end

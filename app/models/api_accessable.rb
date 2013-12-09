# intentional misspelling for fake-"able" parity with other classes
module ApiAccessable
  extend ActiveSupport::Concern

  module ClassMethods
    def has_uuid
      before_save do
        # BACKWARDS COMPATIBILITY: this attribute_method check will be required every time we add an object to the api,
        # so maybe it's worth keeping permanently
        # however, after each successul prod migration, the uuid column of the new model should be updated to be
        # non-NULL
        self.uuid ||= SecureRandom.uuid if self.class.attribute_method?(:uuid)
      end
    end
  end
end

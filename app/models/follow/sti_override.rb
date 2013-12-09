module Follow::StiOverride
  extend ActiveSupport::Concern

  module ClassMethods
    #Hack to override STI.  Uses ints mapped to classnames to save DB space.
    #Sets the column to 'follow_type' to prevent overriding of reserved word "type"
    def inheritance_column
      "follow_type"
    end

    #Hard codes class for Follow.  Could probably build this another way.
    def find_sti_class(type_name)
      Follow::FOLLOW_TYPES[type_name.to_i].constantize
    end

    #Hard codes class for Follow.  Sets type.
    def type_condition(table = arel_table)
      sti_column = table[inheritance_column.to_sym]
      sti_names  = ([self] + descendants).map { |model| model.sti_name }
      sti_column.in(Follow.follow_type_id(sti_names.first))
    end
  end
end
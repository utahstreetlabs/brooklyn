# Sluggable adds validations and behaviors for named models that have both
# human and URL-friendly versions of their names. Ensures that name and slug
# are present, unique, and at most 128 characters in length. Also ensures that
# slug contains only ASCII characters, digits, and hyphens.
#
# Usage:
#
#     class SomeModel
#       include Sluggable
#       has_slug :slug, :attribute    => :name,
#                       :max_length   => 128,
#                       :valid_format => /\w+/
#     end
#
# If you want to append unique suffixes at the end of the slug if the slug has
# been taken already, then pass :unique_suffix => true to has_slug:
#
#     class SomeModel
#       include Sluggable
#       has_slug :slug, :unique_suffix => true
#     end
#
#     SomeModel.create(:name => "John Doe") #=> has slug "john-doe"
#     SomeModel.create(:name => "John Doe") #=> has slug "john-doe-1"
module Sluggable
  extend ActiveSupport::Concern

  module ClassMethods
    # Makes the model sluggable, and runs the validations.
    def has_slug(slug_attribute=:slug, options={})
      options.reverse_merge! :attribute             => :name,
                             :max_length            => 128,
                             :sluggable_max_length  => 128,
                             :valid_format          => /^[a-z0-9\-]+/,
                             :unique_suffix         => false,
                             :validate_slug_if      => lambda { true },
                             :validate_sluggable_if => lambda { true }

      class << self
        # TODO: This isn't inheritable, so it won't work if we ever do STI of
        # sluggable models, but using class_attribute or
        # class_inheritable_accesor or such will override the instance_methods
        # we define in InstanceMethods, since this is run after the modules
        # are included.
        attr_accessor :slug_field, :sluggable_field

        def compute_slug(name)
          name.to_s.parameterize
        end
      end

      self.slug_field = slug_attribute
      self.sluggable_field = options[:attribute]

      if sluggable_field.present?
        validates sluggable_field, :presence   => {
                                     :if  => options[:validate_sluggable_if]
                                   },
                                   :length     => {
                                     :maximum => options[:sluggable_max_length],
                                     :if      => options[:validate_sluggable_if],
                                     :allow_blank => true
                                   }
      end

      validates slug_field, :presence   => {
                              :if => options[:validate_slug_if]
                            },
                            :uniqueness => options[:uniqueness_scope] || {
                              :if => options[:validate_slug_if],
                              :allow_blank => true
                            },
                            :length     => {
                              :maximum => options[:max_length],
                              :if      => options[:validate_slug_if],
                              :allow_blank => true
                            },
                            :format     => {
                              :with => options[:valid_format],
                              :if   => options[:validate_slug_if],
                              :allow_blank => true
                            }


      if options[:unique_suffix]
        include Sluggable::Unique
      elsif sluggable_field.present?
        validates sluggable_field, :uniqueness => options[:uniqueness_scope] || {
                                     :if => options[:validate_sluggable_if]
                                   }
      end

      around_save do |&block|
        begin
          block.call
        rescue ActiveRecord::RecordNotUnique => e
          if e.message =~ /index_[\w]+_on_[\w]*#{self.class.slug_field}[\w]*/
            slug_field = nil
            slugify

            #if slug fails, let it bubble up
            block.call
          end
        end
      end

      before_validation do
        slugify if should_slugify_before_validating?
        true
      end
    end
  end

  module InstanceMethods
    # Sets the slug based on the name, overwriting any previous slug value.
    def slugify
      if slug_field.blank?
        input = sluggable_field if sluggable_field.present?
        self.slug_field = self.class.compute_slug(input)
      end
    end

    # Uses the slug.
    def to_param
      slug_field
    end

    # Generic way to get the slug, whatever DB column this model uses
    def slug_field
      self[self.class.slug_field]
    end

    # Generic way to set the slug, whatever DB column this model uses
    def slug_field=(slug)
      self[self.class.slug_field] = slug
    end

    # Generic way to get the field used for slugging (e.g. name or title),
    # whatever DB column this model uses for that
    def sluggable_field
      self[self.class.sluggable_field]
    end

    # Generic way to set the field used for slugging (e.g. name or title),
    # whatever DB column this model uses for that
    def sluggable_field=(string)
      self[self.class.sluggable_field] = string
    end

    # Overwrite this method on classes to set if this record should
    # auto-generate its slug before validating.
    def should_slugify_before_validating?
      true
    end

    # reset the slug and stash it for possible restoration
    def reset_slug
      if sluggable_field.present?
        @old_slug = slug
        self.slug_field = nil
      end
    end

    def restore_slug
      self.slug_field = @old_slug if @old_slug.present?
    end
  end

  module Unique
    # Sets the person's slug based on his first and last names. If the
    # initially computed slug is not unique, appends a unique serial number to
    # the slug.
    def slugify
      candidate = slug_field.present?? slug_field : self.class.compute_slug(sluggable_field)

      scope_for_dupes = self.class.where(self.class.slug_field => candidate)
      scope_for_dupes = scope_for_dupes.where(["id <> ?", id]) if persisted?

      if scope_for_dupes.size > 0
        suffix = self.class.select(self.class.slug_field).
          where("#{self.class.slug_field} LIKE '#{candidate}-%'").
          map {|p| p.slug_field.split('-').last.to_i}.
          sort.last.to_i + 1

        candidate = "#{candidate}-#{suffix}"
      end

      self.slug_field = candidate
    end
  end
end

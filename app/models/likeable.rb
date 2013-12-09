require 'active_support/concern'
require 'pyramid/models/likeable/likes'

module Likeable
  extend ActiveSupport::Concern

  included do
    # self here is the including class
    @likeable_type = name.underscore.to_sym
    @likeable_id_attr = "#{@likeable_type}_id".to_sym
  end

  # @return [Integer]
  # @see Pyramid::Likeable::Likes#count
  def likes_count(options = {})
    unless instance_variable_defined?(:@likes_count)
      logger.debug("Counting likes for #{self.likeable_type} #{self.id}")
      @likes_count = Pyramid::Likeable::Likes.count(self.id, self.likeable_type, options)
    end
    @likes_count
  end

  # @return [Pyramid::LikesSummary]
  # @see Pyramid::Likeable::Likes#summary
  def likes_summary(options = {})
    logger.debug("Summarizing likes for #{self.likeable_type} #{self.id}")
    Pyramid::Likeable::Likes.summary(self.id, self.likeable_type, options)
  end

  def likeable_type
    self.class.likeable_type
  end

  def likeable_id_attr
    self.class.likeable_id_attr
  end

  module ClassMethods
    attr_reader :likeable_type, :likeable_id_attr

    # Returns the likeable ids of this type sorted by most likes in the last days window.
    #
    # @return ordered [Array of likeable ids]
    # @see Pyramid::Likeable::Likes#recent
    def recently_liked(days, options = {})
      options = options.reverse_merge(per: 24)
      Pyramid::Likeable::Likes.recent(self.likeable_type, days, options)
    end

    # Returns the total number of likes for each likeable of this type.
    #
    # @return [Hash of likeable id => Integer]
    # @see Pyramid::Likeable::Likes#count_many
    def like_counts(likeable_ids, options = {})
      logger.debug("Counting likes for #{self.likeable_type} #{likeable_ids}")
      Pyramid::Likeable::Likes.count_many(self.likeable_type, likeable_ids, options)
    end

    # Returns a subset of this specific type of likeable that the user likes.
    # XXX: Refactor User::Likes#liked to allow a type to be optionally specified => gets rid of the need for this
    #
    # @param [Hash] options
    # @option options [Integer] page
    # @option options [Integer] per
    # @option options [Array] :excluded_ids specifies the ids of listings to exclude from the results
    # @options options [Array] +:exclude_sellers+ +User+s or ids whose listings should not be considered
    # @return [ActiveRecord::Relation]
    # @see #like_visible
    def liked_by(user, options = {})
      logger.debug "Finding #{self.likeable_type} liked by user #{user.id}"
      likes_options = options.merge(type: self.likeable_type, attr: [self.likeable_id_attr])
      ids = user.likes(likes_options).map {|l| l.send(self.likeable_id_attr)}
      relation = like_visible(ids, options)
      relation = relation.page(options.fetch(:page, 1))
      relation = relation.per(options[:per]) if options[:per]
      if options[:excluded_ids].present?
        relation = relation.where("#{quoted_table_name}.id NOT IN (?)", Array.wrap(options[:excluded_ids]))
      end
      if options[:exclude_sellers].present?
        exclude_seller_ids = Array.wrap(options[:exclude_sellers]).compact.map { |u| u.is_a?(User) ? u.id : u }
        relation = relation.where("#{quoted_table_name}.seller_id NOT IN (?)", exclude_seller_ids)
      end
      if options[:exact_order] && ids.any? # order_by_ids returns nil if ids is empty
        relation = relation.order_by_ids(ids)
      end
      relation
    end

    def liked_by_ids(*args)
      liked_by(*args).select("DISTINCT #{quoted_table_name}.id").map(&:id)
    end

    # Returns the subset of the identified likeables which are in a "like visible" state. When in this state, a user's
    # like for the likeable can be displayed to the public.
    #
    # By default this includes all identified likeables. Including classes can override it to attach additional criteria
    # to the returned relation.
    #
    # @param [Array] ids
    # @param [Hash] options
    # @option options [Object] :includes
    # @return [ActiveRecord::Relation]
    def like_visible(ids, options = {})
      relation = where(id: ids)
      relation = relation.includes(options[:includes]) if options[:includes]
      relation
    end
  end
end

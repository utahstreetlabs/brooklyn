require 'brooklyn/sprayer'

class OrderRating < ActiveRecord::Base
  include Brooklyn::Sprayer

  belongs_to :order
  belongs_to :cancelled_order
  belongs_to :user

  # open up user_id since this model is never exposed to users
  attr_accessible :flag, :comments, :user_id, :purchased_at, :failure_reason

  class_attribute :suppress_create_jobs
  @@suppress_create_jobs = false

  module FailureReasons
    NEVER_SHIPPED_CODE = 1

    def self.to_sym(i)
      case i
      when NEVER_SHIPPED_CODE then Order::FailureReasons::NEVER_SHIPPED
      else nil
      end
    end

    def self.to_code(sym)
      case sym
      when Order::FailureReasons::NEVER_SHIPPED then NEVER_SHIPPED_CODE
      else nil
      end
    end
  end

  after_commit on: :create do
    OrderRatings::AfterCreationJob.enqueue(self.id) unless suppress_create_jobs
  end

  def positive?
    flag == true
  end

  def negative?
    flag == false
  end

  def neutral?
    flag.nil?
  end

  def failure_reason
    FailureReasons.to_sym(read_attribute(:failure_reason))
  end

  def failure_reason=(sym)
    write_attribute(:failure_reason, FailureReasons.to_code(sym))
  end

  # Returns all of a user's ratings order by reverse purchase date.
  #
  # @return [ActiveRecord::Relation]
  def self.find_all_for_user(id, options = {})
    where(user_id: id).order('purchased_at DESC').page(options[:page]).per(options[:per])
  end

  # Returns the total number of ratings for a user regardless of flag value.
  def self.count_all_for_user(id)
    where(user_id: id).count
  end

  # Returns all of a user's ratings order by reverse purchase date.
  #
  # @return [ActiveRecord::Relation]
  def self.find_positive_for_user(id, options = {})
    where(user_id: id, flag: true).order('purchased_at DESC').page(options[:page]).per(options[:per])
  end

  # Returns the number of positive ratings for a user.
  def self.count_positive_for_user(id)
    where(user_id: id, flag: true).count
  end

  # Returns the number of negative ratings for a user.
  def self.count_negative_for_user(id)
    where(user_id: id, flag: false).count
  end

  # Returns the total number of a user's rated transactions. Does not consider negative buyer ratings (for which there
  # are no use cases anyway). Note that this method does not return a different result if called on a subclass than
  # when called on this class.
  def self.count_transactions_for_user(id)
    OrderRating.count_positive_for_user(id) + SellerRating.count_negative_for_user(id)
  end

  # Returns the percentage of a user's rated transactions which were successful. A successful transaction is defined
  # as one where the user's rating (whether he was the buyer or seller) was positive.
  #
  # @see #count_positive_for_user
  # @see #count_transactions_for_user
  def self.percent_successful_transactions_for_user(id)
    total_count = OrderRating.count_transactions_for_user(id)
    if total_count > 0
      positive_count = OrderRating.count_positive_for_user(id)
      positive_count / total_count.to_f * 100
    else
      0
    end
  end
end

class Want < ActiveRecord::Base
  include Stats::Trackable

  MINIMUM_PRICE = 0
  # XXX: unify want and secret seller item conditions?
  CONDITIONS = [:new, :used, :new_with_tags, :like_new, :handmade]

  belongs_to :item
  belongs_to :user

  attr_accessible :item_id, :user_id, :max_price, :condition, :notes

  validates :max_price, numericality: {greater_than_or_equal_to: MINIMUM_PRICE, allow_blank: true}, presence: true
  validates :condition, inclusion: {in: CONDITIONS.map(&:to_s)}, allow_blank: true

  after_commit on: :create do
     track_usage(Events::WantItem.new(self))
   end
end

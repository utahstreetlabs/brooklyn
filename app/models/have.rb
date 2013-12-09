class Have < ActiveRecord::Base
  include Stats::Trackable

  belongs_to :item
  belongs_to :user

  attr_accessible :item_id, :user_id

  after_commit on: :create do
     track_usage(Events::HaveItem.new(self))
   end
end

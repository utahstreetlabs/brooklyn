class UserInterest < ActiveRecord::Base
  attr_accessible :user_id, :interest_id
  belongs_to :user
  belongs_to :interest

  after_create do
    Collection.autofollow_list_for_interest(interest).each { |c| user.follow_collection!(c) }
  end


  def self.count_by_interest
    count(:all, select: :interest_id, group: :interest_id)
  end
end

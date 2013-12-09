class Dislike < ActiveRecord::Base
  attr_accessible :user, :listing

  belongs_to :user
  belongs_to :listing
end

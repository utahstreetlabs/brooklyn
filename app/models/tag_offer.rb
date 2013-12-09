class TagOffer < ActiveRecord::Base
  belongs_to :tag
  belongs_to :offer
end

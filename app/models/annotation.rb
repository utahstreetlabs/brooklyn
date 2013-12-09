class Annotation < ActiveRecord::Base
  belongs_to :creator, class_name: 'User'
  belongs_to :annotatable, :polymorphic => true

  validates :url, length: {maximum: 255}, url: true

  attr_accessible :url
end

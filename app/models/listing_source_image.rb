class ListingSourceImage < ActiveRecord::Base
  belongs_to :source, class_name: 'ListingSource'
  attr_accessible :url, :height, :width, :size

  def area
    unless instance_variable_defined?(:@area)
      # if a dimension is nil, assume the image is square and use the other dimension
      self.height = width if height.nil? && width.present?
      self.width = height if width.nil? && height.present?
      @area = height.present? && width.present? ? height * width : nil
    end
    @area
  end

  def height=(value)
    write_attribute(:height, value)
    remove_instance_variable(:@area) if instance_variable_defined?(:@area)
  end

  def width=(value)
    write_attribute(:width, value)
    remove_instance_variable(:@area) if instance_variable_defined?(:@area)
  end
end

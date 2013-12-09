class ShipBase
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :master_addresses, :address_id

  validates :address_id, presence: true,
  inclusion: {:in => lambda {|st| st.master_addresses.map {|a| a.id.to_s}}, allow_blank: true}

  def initialize(attrs = {})
    attrs.each do |name, value|
      send("#{name}=", value)
    end
  end

  def persisted?
    false
  end
end

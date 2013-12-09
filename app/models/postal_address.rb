class PostalAddress < ActiveRecord::Base
  module RefType
    SHIPPING = 'shipping'
    BILLING = 'billing'
    ALL = [SHIPPING, BILLING]
  end

  belongs_to :user
  belongs_to :order
  belongs_to :cancelled_order
  belongs_to :listing

  validates :ref_type, :presence => true, :inclusion => {:in => RefType::ALL, :allow_blank => true}
  validates :line1, :presence => true
  validates :city, :presence => true
  validates :state, :presence => true, :subregion => {:country => :US, :allow_blank => true}
  validates :zip, :presence => true, :postal_code => {:country => :us, :allow_blank => true}
  validates :phone, :presence => true, :phone => {:country => :us, :allow_blank => true}
  validates :name, :presence => true,
    :uniqueness => {:scope => [:user_id, :ref_type, :line1, :order_id, :cancelled_order_id, :listing_id],
                    :case_sensitive => false}

  attr_accessible :ref_type, :line1, :line2, :city, :state, :zip, :phone, :name, :default_address

  normalize_attributes :line1, :line2, :city, :zip, :phone, :name

  def self.new_shipping_address(attrs = {})
    new({ref_type: RefType::SHIPPING}.merge(attrs))
  end

  def self.new_billing_address(attrs = {})
    new({ref_type: RefType::BILLING}.merge(attrs))
  end

  def key_value_pairs
    [:line1, :line2, :city, :state, :zip, :phone].map { |k| [k, self.send(k)] }.select { |a| a[1].present? }
  end

  def default!
    transaction do
      self.class.where(user_id: self.user_id).update_all(default_address: false)
      self.update_attribute(:default_address, true)
    end
  end

  def default?
    self.default_address
  end

  def equivalent?(addr)
    self.attributes.keys.map(&:to_sym).delete_if {|k| [:id, :created_at, :updated_at, :order_id].include?(k)}.each do |k|
      return false unless self.send(k) == addr.send(k)
    end
    true
  end

  def cancel_order!
    self.cancelled_order_id = self.order_id
    self.order_id = nil
    save!(validate: false)
    # not sure why this reload is necessary, but without it the order_id was not being set to null in the db
    reload
  end

  def copy!(other)
    [:user_id, :ref_type, :line1, :line2, :city, :state, :zip, :phone, :name].each do |attr_name|
      self.send("#{attr_name}=", other.send(attr_name))
    end
  end
end

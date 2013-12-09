module SecretSellerHelper
  def secret_seller_condition_choices_for_select
    SecretSellerItem::CONDITIONS.map do |condition|
      [t(condition, scope: 'models.secret_seller_item.attributes.condition'), condition]
    end
  end
end

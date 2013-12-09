xml.instruct!

xml.categories do
  @categories.each do |category|
    xml.category do
      xml.slug category.slug
      xml.name category.name
    end
  end
end

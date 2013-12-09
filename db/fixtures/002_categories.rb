CATEGORIES = [
  {name: 'Accessories',           slug: 'accessories'},
  {name: "Art",                   slug: 'art'},
  {name: 'Bags',                  slug: 'handbags'},
  {name: "Cameras & Photography", slug: 'cameras'},
  {name: "Collectibles",          slug: 'collectibles'},
  {name: "Crafts",                slug: 'crafts'},
  {name: "Electronics",           slug: 'electronics'},
  {name: "Everything Else",       slug: 'everything-else'},
  {name: "Film, Music & Books",   slug: 'film-music-books'},
  {name: "Food",                  slug: 'food'},
  {name: 'Health & Beauty',       slug: 'health-beauty'},
  {name: 'Home',                  slug: 'home'},
  {name: 'Jewelry & Watches',     slug: 'jewelry'},
  {name: 'Kids',                  slug: 'kids'},
  {name: "Men's Clothing",        slug: 'mens-clothing'},
  {name: "Motors",                slug: 'motors'},
  {name: "Musical Instruments",   slug: 'musical-instruments'},
  {name: "Pets",                  slug: 'pets'},
  {name: "Sports & Outdoors",     slug: 'sports-outdoors'},
  {name: "Technology & Gadgets",  slug: 'technology'},
  {name: "Toys & Hobbies",        slug: 'toys-hobbies'},
  {name: "Women's Clothing",      slug: 'clothing'},
  {name: "Women's Shoes",         slug: 'shoes'},
]

CATEGORIES.each do |catmap|
  catmap[:slug] ||= catmap[:name].parameterize
  Category.seed(:slug, catmap)

  # each category has a single dimension 'Condition' with the same two values
  category = Category.find_by_slug(catmap[:slug])
  Dimension.seed(:category_id, :name,
    {:category_id => category.id, :name => 'Condition', :slug => 'condition'}
  )
  dimension = Dimension.find_by_category_id_and_name(category.id, 'Condition')
  DimensionValue.seed(:dimension_id, :value,
    {:dimension_id => dimension.id, :position => 2, :value => 'New'},
    {:dimension_id => dimension.id, :position => 4, :value => 'Used'},
    {:dimension_id => dimension.id, :position => 1, :value => 'New with Tags'},
    {:dimension_id => dimension.id, :position => 3, :value => 'Like New (Worn Once)'},
    {:dimension_id => dimension.id, :position => 5, :value => 'Handmade'},
  )
end

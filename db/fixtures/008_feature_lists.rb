FEATURE_LISTS = [
  {name: "Editor's Picks", slug: 'editors-picks'}
]

FEATURE_LISTS.each do |feature_list_map|
  feature_list_map[:slug] ||= feature_list_map[:name].parameterize
  FeatureList.seed(:slug, feature_list_map)
end

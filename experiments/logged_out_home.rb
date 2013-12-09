ab_test :logged_out_home do
  description "Test the effect of different content for logged out homepage"
  alternatives :graphic_1, :graphic_2, :trending_1, :trending_2
  metrics :loh_conversion
end

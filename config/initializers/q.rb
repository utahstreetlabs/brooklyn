require 'ladon'

if Rails.env.test?
  Ladon.q = Brooklyn::TestQDriver
end

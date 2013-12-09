class UserCards
  include Enumerable
  include Ladon::Logging

  attr_reader :users, :viewer, :cards, :pagination_scope
  delegate :current_page, :num_pages, :limit_value, to: :pagination_scope
  delegate :each, to: :cards

  def initialize(users, viewer, pagination_scope = nil)
    @users = users
    @pagination_scope = pagination_scope.present? ? pagination_scope : users
    @viewer = viewer
    @cards = UserCard.create_all(users, viewer)
  end
end

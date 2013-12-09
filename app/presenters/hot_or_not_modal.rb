class HotOrNotModal
  include Ladon::Logging

  attr_reader :listing, :photo

  def initialize(suggestions)
    @listing = suggestions.listings.sample
    @photo = suggestions.photos[@listing.id]
  end

  def viewer
    suggestions.user
  end
end

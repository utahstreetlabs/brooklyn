class Api::Listings::ActiveController < ApiController
  respond_to :xml, :json

  def index
    search_options = params.symbolize_keys.slice(:seller_id, :sort, :page, :per_page, :created_after, :created_before, :with_sold, :extra)
    listings = ListingSearcher.new(search_options.reverse_merge(seller_id: @user.id, with_sold: false)).all
    respond_with({ listings: listings.map { |l| l.api_hash(summary: false, extra: params[:extra]) } })
  end

  def count
    render_jsend success: {count: @user.listings_for_sale.count }
  end
end


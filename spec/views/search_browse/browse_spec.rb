require "spec_helper"

describe "search_browse/browse" do
  before { view.stubs(browse_for_sale_path_tags_path: '/a/path') }
  let(:viewer) { stub('viewer', id: 12345, person_id: 54321, inactive?: false) }
  let(:seller) do
    stub('seller', id: 34567, person_id: 76543, name: 'Snidely Whiplash', profile_photo: stub('seller photo', url: '/seller.jpg'), inactive?: false, guest?: true, firstname: 'Snidely')
  end
  let(:listing) do
    stub('listing', id: 9876, title: 'Pork Pie Hat', price: 49.99, total_price: 54.99, photos: [], seller: seller,
      sold_by?: false, sold?: false)
  end
  let(:listing_photo) do
    stub_everything('listing_photo', listing: listing, file: stub(medium: stub(url: '')))
  end
  let(:searcher) { stub_searcher_with_listings([listing]) }
  let(:results) { stub_listing_results(viewer, searcher.all) }

  before do
    assign(:searcher, searcher)
    assign(:results, results)
    act_as_rfb(viewer)
    Redhook::Person.stubs(:create_async).returns(nil)
    view.stubs(:display_requested?).returns(false)
    view.stubs(:visitor_identity).returns('hamburgler')
  end

  context "sidebar" do
    # there's some interpolation of these classes in the template, so we just use the real thing
    let(:category) { Category.new(name: 'Manga', slug: 'manga') }
    let(:dv) { DimensionValue.new(value: 'Mint') }
    let(:conditions) { stub(selected: [], alphabetical: [[dv, true, 3]]) }

    let(:category_searcher) do
      stub_searcher_with_listings([listing],
        categories: stub(selected: [stub(instance: category, count: 4)], unselected: []), conditions: conditions)
    end

    let(:all_searcher) do
      stub_searcher_with_listings([listing],
        categories: stub(selected: [], unselected: [[category, 4]]), conditions: conditions)
    end

    context "viewing listings in a specific category" do
      before { dv.stubs(:id).returns(1) }
      it "should show appropriate dimensions" do
        render :partial => "search_browse/sidebar", :locals => { searcher: category_searcher }
        rendered.should have_css('#condition-container li')
      end
    end

    context "viewing listings with no category" do
      it "shouldn't show any dimensions" do
        render :partial => "search_browse/sidebar", :locals => { searcher: all_searcher }
        rendered.should_not have_css('#condition-container li')
      end
    end
  end
end

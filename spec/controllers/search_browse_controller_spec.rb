require 'spec_helper'

describe SearchBrowseController do
  describe "#browse" do
    let(:searcher) { stub_searcher_with_listings [] }
    let(:results) { stub('results') }

    before do
      ListingSearcher.stubs(:new).returns(searcher)
      ListingResults.stubs(:new).returns(results)
    end

    context "happily" do
      before do
        searcher.expects(:error)
        get :browse
      end

      it "assigns searcher" do
        assigns(:searcher).should == searcher
      end

      it "assigns results" do
        assigns(:results).should == results
      end

      it "does not assign flash alert" do
        flash[:alert].should be_nil
      end
    end

    context "with error" do
      before do
        searcher.expects(:error).returns(stub_everything)
        get :browse
      end

      it "assigns searcher" do
        assigns(:searcher).should == searcher
      end

      it "does not assigns results" do
        assigns(:results).should be_nil
      end

      it "assigns flash alert" do
        flash[:alert].should be
      end
    end

    describe "legacy redirects" do
      let(:ids) { ['1', '2'] }
      let(:tags) { [stub('t1', slug: 'cake'), stub('t2', slug: 'butter')] }
      it "should redirect requests with tags to new path_tag urls" do
        Tag.expects(:where).with(id: ids).returns(tags)
        get :browse, tags: ids
        response.should redirect_to(browse_for_sale_path(path_tags: tags.map(&:slug).join('/')))
      end
    end
  end
end

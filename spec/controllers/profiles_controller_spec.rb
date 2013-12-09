require 'spec_helper'

describe ProfilesController do
  context "#show" do
    let(:profile_user) { stub_user 'Infanta Jones' }
    before { User.stubs(:find_by_slug!).with(profile_user.slug).returns(profile_user) }

    it 'succeeds' do
      listings = [stub_listing('Gear-Marked Gauntlets', id: 111),
                  stub_listing('Beech Green Belt', id: 222),
                  stub_listing('Legguards of Winnowing Wind', id: 333)]
      searcher = stub_searcher_with_listings listings
      ListingSearcher.expects(:new).with(has_entry('seller_id' => profile_user.id)).returns(searcher)
      do_get
      assigns(:results).objects.should == listings
      response.should render_template(:show)
    end

    it 'returns not found when the user is not active' do
      profile_user.stubs(:registered?).returns(false)
      do_get
      response.code.to_i.should == 404
    end

    def do_get
      get :show, id: profile_user.slug
    end
  end

  describe '#liked' do
    let(:profile_user) { stub_user 'Angor Mor' }
    before { User.stubs(:find_by_slug!).with(profile_user.slug).returns(profile_user) }

    let(:listings) do
      [stub_listing('Roaring Mask of Bethekk', id: 111),
       stub_listing('Fireheart Necklace', id: 222),
       stub_listing('Pauldrons of the High Requiem', id: 333)]
    end
    let(:stats) { {} }

    it 'succeeds' do
      profile_user.expects(:liked).returns(listings)
      do_get
      assigns(:results).objects.should == listings
      response.should render_template(:liked)
    end

    def do_get
      get :liked, id: profile_user.slug
    end
  end
end

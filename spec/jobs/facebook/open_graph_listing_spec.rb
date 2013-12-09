require 'spec_helper'

describe Facebook::OpenGraphListing do
  class Listing
  end

  class User
  end

  let(:user) { stub_user('Axl Rose') }
  let(:listing) { stub_listing 'Cocaine, 1kg', seller: user }
  let(:listing_url) { 'http://clickety/click' }

  subject { Facebook::OpenGraphListing }

  describe "#open_graph_post" do
    let(:profile) { stub('profile', id: 5555, uid: 6666) }
    let(:actor) { stub_user('Skunk Walrustache Baxter') }
    let(:listing) { stub_listing 'The years, reeled', approved?: true }
    let(:listing_url) { "/url/to/listing" }
    let(:og_postable) { true }

    before { actor.person.expects(:for_network).with(:facebook).returns(profile) }

    context "there is a facebook profile" do
      before { profile.expects(:og_postable?).returns(og_postable) }

      context "open graph is allowed" do
        before { subject.expects(:open_graph_object_props).returns({}) }

        it 'posts to the facebook timeline' do
          profile.expects(:post_to_ticker)
          subject.open_graph_post(listing, listing_url, actor, :post)
        end

        it 'catches exceptions raised from og posts' do
          profile.expects(:post_to_ticker).raises("Boom!")
          expect { subject.open_graph_post(listing, listing_url, actor, :post) }.not_to raise_error
        end
      end

      context "open graph is not allowed" do
        let(:og_postable) { false }
        it 'does not post if open graph is not allowed' do
          profile.expects(:post_to_ticker).never
          subject.open_graph_post(listing, listing_url, actor, :post)
        end
      end
    end


    context "there is no facebook profile" do
      let(:profile) { nil }
      it 'does not post' do
        profile.expects(:post_to_ticker).never
        subject.open_graph_post(listing, listing_url, actor, :post)
      end
    end
  end
end

require 'spec_helper'

describe ActorCardHelper do
  describe '#actor_card' do
    let(:actor) { stub_user 'Bill Nye' }
    let(:first_listing) { stub('listing', title: 'Science', created_at: Time.zone.now) }
    let(:listings) { [first_listing] }
    let(:story) { stub('story', created_at: Time.zone.now, actor: actor,
                       action: 'listing_liked', type: 'actor_multi_listing', listings: listings, count: 3) }
    let(:photos) { [stub('photo', listing: first_listing, created_at: Time.zone.now, file: stub('file', small: stub('small photo', url: "http://example.com/science.jpg")))] }
    let(:card) { stub('card', actor: actor, photos: photos, listings: listings, story: story, visible_listings_count: 1, likes_count: 1, collections_count: 1 ) }

    context 'when logged in' do
      let(:viewer) { stub_user 'Ian Anderson' }
      before do
        helper.stubs(:logged_in?).returns(true)
        helper.stubs(:current_user).returns(viewer)
      end

      context 'and viewing own story' do
        before do
          story.stubs(:actor).returns(viewer)
          card.stubs(:actor).returns(viewer)
          story.stubs(:generated_by?).with(viewer).returns(true)
        end

        it 'shows "You" as the actor name' do
          do_actor_card.should have_content('You')
        end

        it 'does not include a follow control' do
          do_actor_card.should_not have_css('[data-follower-count]')
        end
      end

      context "and viewing a followee's story" do
        before do
          story.stubs(:generated_by?).with(viewer).returns(false)
          viewer.stubs(:following?).with(actor).returns(true)
        end

        it "shows the actor's name" do
          do_actor_card.should have_content(actor.name)
        end

        it 'includes an unfollow button' do
          do_actor_card.should have_css('[data-action=unfollow]')
        end
      end

      context "and viewing an rfb's story" do
        before do
          story.stubs(:generated_by?).with(viewer).returns(false)
          viewer.stubs(:following?).with(actor).returns(false)
        end

        it "shows the actor's name" do
          do_actor_card.should have_content(actor.name)
        end

        it 'includes a follow button' do
          do_actor_card.should have_css('[data-action=follow]')
        end
      end
    end

    context 'when not logged in' do
      before do
        helper.stubs(:logged_in?).returns(false)
      end

      it "shows the actor's name" do
        do_actor_card.should have_content(actor.name)
      end

      it 'does not include a follow control' do
        do_actor_card.should_not have_css('[data-follower-count]')
      end
    end

    def do_actor_card
      helper.actor_card(card)
    end
  end
end

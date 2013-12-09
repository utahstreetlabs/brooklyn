require 'spec_helper'
require 'progress_bar_helper'

describe ListingsHelper do
  context "when determining progress" do
    (ListingsHelper::ORDER_STEPS.keys).each do |step|
      let(:listing) { stub(order: stub(status: step)) }

      it "properly renders progress for '#{step.to_s}'" do
        listing_order_progress_bar(listing)
      end
    end
  end

  describe "#listing_likers" do
    let(:liker1) { stub_user('Ix Equilibrium') }
    let(:like1) { stub('like1', user_id: liker1.id) }
    let(:liker2) { stub_user('Madder Rose') }
    let(:like2) { stub('like2', user_id: liker2.id) }
    let(:liker3) { stub_user('Velocity Girl') }
    let(:like3) { stub('like3', user_id: liker3.id) }
    let(:liker4) { stub_user('Elvis Costello') }
    let(:like4) { stub('like4', user_id: liker4.id) }
    let(:liker5) { stub_user('Jimi Hendrix') }
    let(:like5) { stub('like5', user_id: liker5.id) }

    let(:viewer) { nil }
    let(:likes) { [] }
    let(:likers) { [] }
    let(:liker_ids) { likers.map(&:id) }
    let(:likes_summary) { stub('likes_summary', count: liker_ids.size, liker_ids: liker_ids) }
    subject { helper.listing_likers(likes_summary, viewer) }

    def subject_should_have_liker_images
      likers.each {|liker| expect(subject).to have_selector("img[title='#{liker.name}']")}
    end
    context "when logged in" do
      let(:viewer) { liker1 }
      before do
        act_as_rfb(viewer)
        viewer.expects(:find_ordered_by_following_and_followers).with(liker_ids).returns(likers)
      end

      context 'when I am the only liker' do
        let(:likes) { [like1] }
        let(:likers) { [liker1] }

        it "shows that I am the only liker" do
          subject_should_have_liker_images
          expect(subject).to have_content('You')
        end
      end

      context 'when there are two other likers' do
        let(:likes) { [like1, like2, like3] }
        let(:likers) { [liker1, liker2, liker3] }

        it "shows me and two named likers" do
          subject_should_have_liker_images
          expect(subject).to have_content("You, #{liker2.name}, and #{liker3.name}")
        end
      end

      context 'when there are a bunch of likers' do
        let(:likes) { [like1, like2, like3, like4, like5] }
        let(:likers) { [liker1, liker2, liker3, liker4, liker5] }

        it "shows me, two named likers and a few others" do
          subject_should_have_liker_images
          expect(subject).to have_content("You, #{liker2.name}, #{liker3.name}, and 2 others")
        end
      end
    end

    context "when not logged in" do
      let(:viewer) { nil }
      before do
        act_as_anonymous
        User.expects(:find_ordered_by_followers).with(liker_ids).returns(likers)
      end

      context "when there is one liker" do
        let(:likes) { [like1] }
        let(:likers) { [liker1] }

        it "shows one named liker" do
          subject_should_have_liker_images
          expect(subject).to have_content("#{liker1.name}")
        end
      end

      context "when there are two likers" do
        let(:likes) { [like1, like2] }
        let(:likers) { [liker1, liker2] }
        it "shows two named likers" do
          subject_should_have_liker_images
          expect(subject).to have_content("#{liker1.name} and #{liker2.name}")
        end
      end

      context "when there are a bunch of likers" do
        let(:likes) { [like1, like2, like3, like4, like5] }
        let(:likers) { [liker1, liker2, liker3, liker4, liker5] }
        it "shows two named likers and a few others" do
          subject_should_have_liker_images
          expect(subject).to have_content("#{liker1.name}, #{liker2.name}, and 3 others")
        end
      end
    end
  end

  describe "#comment_sanitize_and_convert" do
    let(:comment) { stub('comment', text: text, user_id: 1) }
    let(:commenter) { stub_user('Vernon Reid') }
    let(:user) { stub_user('Corey Glover') }
    let(:rendered) { helper.comment_sanitize_and_convert(comment, commenter) }
    let(:html) { Capybara::Node::Simple.new(rendered) }
    before do
      User.stubs(:where).returns([commenter])
      helper.stubs(:logged_in?).returns(true)
      helper.stubs(:current_user).returns(user)
    end

    context "empty text" do
      let(:text) { '' }
      it "returns empty string" do
        expect(rendered).to eq(text)
      end
    end

    context "text with no keywords" do
      let(:text) { 'Hello world!' }
      it "returns text as is" do
        expect(rendered).to eq(text)
      end
    end

    context "text with tags but no keywords" do
      let(:text) { "Hello <div>world!</div> <span data-kw-type=\"tag\">#greeting</span>" }
      let(:markup) { "Hello world! #greeting" }
      it "returns text without tags" do
        expect(rendered).to eq(markup)
      end
    end

    context "hashtag keyword with no id attribute" do
      let(:text) { "Hello world! <span data-role=\"kw\" data-kw-name=\"#greeting\" "\
        "data-kw-type=\"tag\">#greeting</span>" }
      it "returns text with HTML link with no href attribute" do
        expect(html[:href]).to be_nil
      end
    end

    context "hashtag keyword" do
      let(:text) { "Hello world! <span data-role=\"kw\" data-kw-id=\"greeting\" "\
        "data-kw-name=\"#greeting\" data-kw-type=\"tag\">#greeting</span>" }
      let(:link) { html.find('a') }
      it "returns text with HTML link referencing for sale listing page filtered by tag" do
        expect(link[:href]).to eq(browse_for_sale_path('greeting'))
      end
      it 'adds the slug as a data attribute' do
        expect(link[:'data-tag-slug']).to eq('greeting')
      end
    end

    context "copious follower keyword" do
      let(:text) { "Hello world! <span data-role=\"kw\" data-kw-slug=\"john-doe\" data-kw-id=\"12345\" "\
        "data-kw-name=\"@John Doe\" data-kw-type=\"cf\">@John Doe</span>" }
      let(:link) { html.find('a') }
      it "returns text with keyword HTML link referencing copious user profile page" do
        User.stubs(:find_by_id).returns('john-doe')
        expect(link[:href]).to eq(public_profile_path('john-doe'))
      end
    end

    context "facebook user keyword" do
      let(:text) { "Hello world! <span data-role=\"kw\" data-kw-id=\"123456789\" "\
        "data-kw-name=\"@John Doe\" data-kw-type=\"fb\">@John Doe</span>" }
      let(:span) { html.find('span') }
      it "returns text with HTML span" do
        expect(span.text).to eq('@John Doe')
      end
    end

    context "multiple keywords" do
      let(:text) { "Hello world! <span data-role=\"kw\" data-kw-id=\"greeting\" "\
        "data-kw-name=\"#greeting\" data-kw-type=\"tag\">#greeting</span> <span data-role=\"kw\" "\
        "data-kw-slug=\"john-doe\" data-kw-id=\"12345\" data-kw-name=\"@John Doe\" "\
        "data-kw-type=\"cf\">@John Doe</span> <span data-role=\"kw\" data-kw-id=\"123456789\" "\
        "data-kw-name=\"@Jane Doe\" data-kw-type=\"fb\">@Jane Doe</span>" }
      let(:markup) { "Hello world! <a href=\"#{browse_for_sale_path('greeting')}\">#greeting</a> "\
        "<a href=\"#{public_profile_path('john-doe')}\">@John Doe</a> <span>@Jane Doe</span>" }
      let(:hash_link) { html.find('a[class=hashtag-link]') }
      let(:profile_link) { html.all('a').last }
      let(:span) { html.find('span') }
      it "returns text with multiple HTML tags" do
        User.stubs(:find_by_id).returns('john-doe')
        expect(hash_link[:href]).to eq(browse_for_sale_path('greeting'))
        expect(profile_link[:href]).to eq(public_profile_path('john-doe'))
        expect(span.text).to eq('@Jane Doe')
      end
    end
  end

  context "when rendering the collection dropdown" do
    let(:collection1) { FactoryGirl.create(:collection, created_at: Time.zone.now, name: 'A') }
    let(:collection2) { FactoryGirl.create(:collection, created_at: 1.day.ago, name: 'b') }
    let(:collection3) { FactoryGirl.create(:collection, created_at: 2.day.ago, name: 'C') }
    let(:viewer) { stub_user('Duncanthrax the Bellicose') }

    before do
      helper.stubs(:current_user).returns(viewer)
    end

    describe "#save_listing_to_collection_list" do
      it 'sorts the collections by name' do
        collections = [collection3, collection1, collection2]
        list = helper.save_listing_to_collection_list(collections)
        list.first[0].should == collection1.name
        list.second[0].should == collection2.name
        list.third[0].should == collection3.name
      end
    end
  end
end

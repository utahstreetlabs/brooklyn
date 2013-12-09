require 'spec_helper'

describe Tag do
  it_should_behave_like "a sluggable model", :tag

  describe "finding or creating all new tags" do
    before do
      @names = ['post-metal', 'sludge metal', 'progressive rock']
      @tags = Tag.find_or_create_all_by_name(@names)
    end

    it "returns every tag" do
      @tags.should have(@names.size).tags
    end

    it "saves every tag" do
      @tags.each {|t| t.persisted?.should be_true}
    end
  end

  describe "finding or creating some new tags" do
    before do
      @names = ['post-metal', 'sludge metal', 'progressive rock']
      FactoryGirl.create(:tag, :name => @names.first)
      @tags = Tag.find_or_create_all_by_name(@names)
    end

    it "returns every tag" do
      @tags.should have(@names.size).tags
    end

    it "saves every tag" do
      @tags.each {|t| t.persisted?.should be_true}
    end

    it "doesn't create a tag if its slug matches an existing tag with a different name" do
      existing = Tag.find_by_slug('post-metal')
      tags = Tag.find_or_create_all_by_name(['post metal'])
      tags.first.should == existing
    end
  end

  describe ".with_count_for_listings" do
    let :tags do
      %w(leather snakeskin black travel).map do |tag|
        FactoryGirl.create(:tag, :name => tag)
      end
    end

    let :listings do
      (0..3).map do |i|
        FactoryGirl.create(:incomplete_listing, :tags => tags[1..i])
      end
    end

    subject do
      Tag.with_count_for_listings(listings)
    end

    it "returns all tags with at least one element" do
      should have(listings.size - 1).elements
    end

    it "retrieves the amount of listings with said tag" do
      tag = lambda { |name| Tag.find_by_name(name) }

      subject[tag["leather"]].should == 0
      subject[tag["snakeskin"]].should == 3
      subject[tag["black"]].should == 2
      subject[tag["travel"]].should == 1
    end

    it "rejects tags passed in as exceptions" do
      tags = Tag.with_count_for_listings(listings, ["snakeskin"])

      tags.should_not have_key(Tag.find_by_slug("snakeskin"))
      tags.should have_key(Tag.find_by_slug("black"))
    end
  end

  context "#new_size_tag" do
    it "creates a new size tag" do
      tag = Tag.new_size_tag("foo")
      tag.type.should == 's'
      tag.persisted?.should be_true
    end
  end

  context "#destroy" do
    let(:subject) { FactoryGirl.create(:tag) }

    it "invokes observer" do
      IndexTagObserver.instance.expects(:after_destroy_with_listings).with(subject, subject.listings)
      subject.destroy
    end

    it "promotes the subtags if deleting a primary" do
      subtag = FactoryGirl.create(:subtag)
      tag = subtag.primary
      tag.destroy
      subtag.reload.primary?.should be_true
    end
  end

  context "#merge" do
    1.upto(2).each do |i|
      let("listing#{i}".to_sym) { FactoryGirl.create(:incomplete_listing) }
      let("tag#{i}".to_sym) do
        tag = FactoryGirl.create(:tag)
        tag.listings << send("listing#{i}".to_sym)
        tag
      end
    end
    let(:merge_ids) { [tag1.id] }

    it "updates sub-tag's primary id" do
      tag2.merge(merge_ids)
      Tag.find(tag1.id).primary_tag_id.should == tag2.id
    end
  end

  context "#promote" do
    it "promotes" do
      tag = FactoryGirl.create(:subtag)
      tag.promote
      tag.primary?.should be_true
    end

    it "unfeatures listing from primary tag when listing is tagged with subtag" do
      subtag = FactoryGirl.create(:subtag)
      tag = subtag.primary
      listing = FactoryGirl.create(:active_listing)
      listing.tags << subtag
      tag.feature(listing)
      listing.featured_for_tag?(tag).should be_true
      subtag.promote
      listing.featured_for_tag?(tag, force_reload: true).should be_false
    end
  end

  context "#subtag?" do
    it "returns true for a subtag" do
      tag = FactoryGirl.create(:subtag)
      tag.subtag?.should be_true
    end

    it "returns false for not a subtag" do
      tag = FactoryGirl.create(:tag)
      tag.subtag?.should be_false
    end
  end

  context "#primary?" do
    it "returns true for a primary tag" do
      tag = FactoryGirl.create(:tag)
      tag.primary?.should be_true
    end

    it "returns false for not a primary tag" do
      tag = FactoryGirl.create(:subtag)
      tag.primary?.should be_false
    end
  end

  context "#primary" do
    it "returns self if it is a primary tag" do
      tag = FactoryGirl.create(:tag)
      tag.primary.should == tag
    end

    it "returns primary if it is a subtag" do
      tag = FactoryGirl.create(:subtag)
      tag.primary.id.should == tag.primary_tag_id
    end
  end

  describe '#related_tags' do
    let(:subtag) { FactoryGirl.create(:subtag) }
    let(:tag) { subtag.primary }

    it 'returns the primary tag and all subtags' do
      subtag.related_tags.should include subtag
      subtag.related_tags.should include tag
    end

    it 'has a helper called #related_tag_ids for getting just the ids' do
      subtag.related_tag_ids.should include subtag.id
      subtag.related_tag_ids.should include tag.id
    end
  end
end

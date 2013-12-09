require 'spec_helper'

describe ListingSearcher do
  let(:scope) { stub('scope') }
  let(:search_result) { stub('search result') }
  before { scope.stubs(:search).returns(search_result) }

  context "in the presence of total and complete failure" do
    before { scope.stubs(:search).raises(Errno::ECONNREFUSED) }
    subject { ListingSearcher.new({}, scope) }

    it "has an error" do
      subject.error.should be
    end
  end

  context "normally" do
    subject { ListingSearcher.new({}, scope) }

    it "does not have an error" do
      subject.error.should be_nil
    end
  end

  context "#tags" do
    let(:t1) { stub('tag1', name: 'One', slug: 'one') }
    let(:t2) { stub('tag2', name: 'Two', slug: 'two') }
    let(:t3) { stub('tag3', name: 'Three', slug: 'three') }
    subject { ListingSearcher.new({tags: [t1.slug]}, scope) }

    before do
      search_returns_facet_rows(:tag_facets,
        [stub(count: 4, value: "#{t1.slug}##{t1.name}"),
         stub(count: 4, value: "#{t2.slug}##{t2.name}"),
         stub(count: 2, value: "#{t3.slug}##{t3.name}")])
    end

    it "should return selected tags in selected" do
      subject.tags.selected.map(&:slug).should == [t1.slug]
      subject.tags.selected.map(&:name).should == [t1.name]
    end

    it "should return unselected tags and counts" do
      subject.tags.unselected.to_a.sort_by { |t, s, c| c }.should == [
        [OpenStruct.new(slug: t3.slug, name: t3.name), false, 2],
        [OpenStruct.new(slug: t2.slug, name: t2.name), false, 4]
      ]
    end
  end

  context "#conditions" do
    let(:new) { stub('condition', slug: 'new', name: 'New') }
    let(:nwt) { stub(slug: 'new-with-tags', name: 'New with Tags') }
    let(:used) { stub(slug: 'used', name: 'Used') }
    let(:wo) { stub(slug: 'worn-once', name: 'Worn Once') }
    let(:condition_facets) { [new, nwt, used, wo].map { |cf| stub(count: 4, value: "#{cf.slug}##{cf.name}") } }
    subject { ListingSearcher.new({conditions: ['new', 'worn-once']}, scope) }

    before do
      search_returns_facet_rows(:condition_facet, condition_facets)
    end

    it "should return selected dimensions in selected" do
      subject.conditions.selected.map(&:slug).should == [new, wo].map(&:slug)
      subject.conditions.selected.map(&:name).should == [new, wo].map(&:name)
    end

    it "should return unselected conditions and counts" do
      subject.conditions.unselected.to_a.sort_by { |t, s, c| t.slug }.should == [
        [OpenStruct.new(slug: nwt.slug, name: nwt.name), false, 4],
        [OpenStruct.new(slug: used.slug, name: used.name), false, 4]
      ]
    end
  end

  context "#categories" do
    let(:cats) { stub('category', slug: 'cats', name: 'Cats') }
    let(:dogs) { stub('category', slug: 'dogs', name: 'Dogs') }
    let(:categories) { [cats, dogs].map { |c| stub(c.name, count: 2, value: "#{c.slug}##{c.name}") } }
    let(:selected) { categories.first }

    it "should return categories that exist in the query results" do
      search_returns_facet_rows(:category_facet, categories)
      ls = ListingSearcher.new({}, scope)
      ls.categories.selected.should have(0).items
      ls.categories.unselected.should have(2).items
    end

    it "should return categories that exist in the query results" do
      Category.expects(:find_by_slug).with(cats.slug).returns(cats)
      search_returns_facet_rows(:category_facet, [selected])

      ls = ListingSearcher.new({category: cats.slug}, scope)
      ls.categories.selected.should have(1).items
      ls.categories.unselected.should have(0).items
    end
  end

  def search_returns_facet_rows(facet, rows)
    search_result.expects(:facet).with(facet).returns(stub('facet', rows: rows))
  end
end

require 'spec_helper'

describe InternalListing do
  context "#cancellable_uids" do
    let!(:seller) { FactoryGirl.create(:registered_user) }
    let!(:active) { FactoryGirl.create(:active_listing, seller: seller, source_uid: 'abc') }
    let!(:nosource) { FactoryGirl.create(:active_listing, seller: seller) }
    let!(:otherseller) { FactoryGirl.create(:active_listing, source_uid: 'ghi') }
    let!(:sold) { FactoryGirl.create(:sold_listing, seller: seller, source_uid: 'jkl') }

    it "cancels listings not included in latest list of uids" do
      uids = InternalListing.cancellable_uids(seller)
      uids.should == Set.new([active.source_uid])
    end
  end

  context "synchronization" do
    let(:seller) { FactoryGirl.create(:registered_user) }
    let(:category) { FactoryGirl.create(:category) }
    let(:category2) { FactoryGirl.create(:category) }
    let(:categories) { { handbags: category, accessories: category2 } }
    let(:tag) { FactoryGirl.create(:tag) }
    let(:tag2) { FactoryGirl.create(:tag) }
    let(:tags) { { tag.slug => tag, tag2.slug => tag2 } }
    let(:price) { 100.00 }
    let(:shipping) { 10.00 }
    let(:attributes) do
      {title: 'Stella Handbag', description: 'Nice Stella Handbag', price: 100.00, shipping: shipping}
    end
    let(:attributes2) { attributes.merge(title: 'Excellent Stella Handbag') }
    let(:paths) { ['spec/fixtures/handbag.jpg', 'spec/fixtures/hamburgler.jpg'] }
    let(:old_file) { Brooklyn::CarrierWave::LocalImageFile.new(paths.first) }
    let(:files) { paths.map { |path| Brooklyn::CarrierWave::LocalImageFile.new(path) } }

    let(:adapter) do
      stub(uid: 'abc', pricing_version: nil, category_slug: :handbags, condition: nil,
        attributes: attributes, photo_files: files, tag_names_no_create: [tag.name, tag2.name], tag_names: nil)
    end
    let!(:adapter2) do
      stub(uid: 'abc', pricing_version: 1, category_slug: :accessories, condition: nil,
        attributes: attributes2, photo_files: files, tag_names_no_create: nil, tag_names: nil)
    end

    context "#attach_photos" do
      let(:listing) { FactoryGirl.create(:incomplete_listing) }
      subject { listing.photos }
      before do
        old_photo = subject.build
        old_photo.file.cache!(old_file)
        old_photo.save!
        files.each_with_index { |f,i| f.stubs(:uid).returns("file#{i}") }
        listing.attach_photos(files)
      end
      its(:count) { should == 2 }
      it "attaches the files in the right order" do
        subject.first.file.filename.should == File.basename(paths.first)
      end
      it 'stores the source_uid values' do
        subject.first.source_uid.should == files.first.uid
        subject.last.source_uid.should == files.last.uid
      end
    end

    context "#create_or_update_from_source_adapter" do
      let!(:listing) { InternalListing.create_or_update_from_source_adapter(seller, adapter, categories, tags)[0] }

      context "for a new listing" do
        subject { listing }

        its(:source_uid) { should == adapter.uid }
        its(:title) { should == attributes[:title] }
        its(:category) { should == category }
        its(:tags) { should == [tag, tag2] }
        its(:price) { should == price }
        its(:shipping) { should == shipping }
        it "attaches photos" do
          subject.photos.length.should == 2
        end
      end

      context "for an existing listing" do
        subject { InternalListing.create_or_update_from_source_adapter(seller, adapter2, categories, tags)[0] }

        its(:title) { should == attributes2[:title] }
        its(:description) { should == attributes[:description] }
        its(:pricing_version) { should == Brooklyn::PricingScheme.current_version }
        its(:price) { should == price }
        its(:category) { should == category2 }
      end
    end

    context "#reorder_photos_by_uuid" do
      subject { FactoryGirl.create(:active_listing) }
      before do
        3.times do |i|
          FactoryGirl.create(:listing_photo, listing: subject)
        end
      end

      it "works" do
        reversed = subject.photos(order: :position).map(&:uuid).reverse
        subject.reorder_photos_by_uuid(reversed)
        subject.reload
        subject.photos(order: :position).map(&:uuid).should == reversed
      end

      context "with an unmatched UUID" do
        it "raises an exception" do
          extra = subject.photos(order: :position).map(&:uuid).reverse + ['abcdefg']
          expect { subject.reorder_photos_by_uuid(extra) }.to raise_exception
        end
      end

      context "with a missing UUID" do
        it "raises an exception" do
          missing = subject.photos(order: :position).map(&:uuid).reverse[0..2]
          expect { subject.reorder_photos_by_uuid(missing) }.to raise_exception
        end
      end
    end

    context "#tags_from_cache" do
      let(:tag) { FactoryGirl.create(:tag) }
      let(:cache) { { tag.slug => tag } }
      let(:new_tag_name) { 'Not the same one' }
      let(:tag_names) { [tag.name, new_tag_name] }
      subject { InternalListing.tags_from_cache(tag_names, cache, create) }

      context "when create == false" do
        let(:create) { false }
        its(:count) { should == 1 }
        it "should contain the original tag" do
          subject[tag.slug].should == tag
        end
      end

      context "when create == true" do
        let(:create) { true }
        its(:count) { should == 2 }
        it "should contain the original tag" do
          subject[tag.slug].should == tag
        end
        it "should contain a new tag" do
          subject[Tag.compute_slug(new_tag_name)].name.should == new_tag_name
        end
      end
    end

    context "#condition" do
      subject { FactoryGirl.create(:active_listing) }
      let(:condition) do
        FactoryGirl.create(:dimension, category_id: subject.category_id, name: 'condition', slug: 'condition')
      end
      let!(:new_condition) { FactoryGirl.create(:dimension_value, dimension_id: condition.id, value: 'New') }
      let!(:used_condition) { FactoryGirl.create(:dimension_value, dimension_id: condition.id, value: 'Used') }

      before do
        subject.dimension_values << new_condition
      end

      context "for a listing with a current condition" do
        it "returns the current condition" do
          subject.condition_dimension_value.should == new_condition
          subject.condition.should == 'New'
        end

        it "updates the current condition" do
          subject.condition = 'used'
          subject.condition_dimension_value.should == used_condition
          subject.condition.should == 'Used'
        end

        it "removes the condition if set to nil" do
          subject.condition = nil
          subject.condition_dimension_value.should_not be
        end
      end

      context "for a listing without a current condition" do
        it "sets the current condition" do
          subject.condition = 'used'
          subject.condition_dimension_value.should == used_condition
          subject.condition.should == 'Used'
        end
      end
    end
  end
end

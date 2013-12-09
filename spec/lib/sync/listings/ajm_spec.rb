require 'spec_helper'

describe Sync::Listings::Ajm do
  describe Sync::Listings::Ajm::Adapter do
    let(:uid) { 'abcdef' }
    let(:title) { 'Red Ryder BB' }
    let(:description) { "You'll shoot your eye out." }
    let(:price) { 50.00 }
    let(:msrp) { 99.00 }
    let(:shipping) { 5.00 }
    let(:img1) { 'http://example.com/images/red-ryder/1.jpg' }
    let(:img2) { 'http://example.com/images/red-ryder/2.jpg' }
    let(:img3) { 'http://example.com/images/red-ryder/3.jpg' }
    let(:category) { 'Womens Accessories' }
    let(:condition) { 'NEW' }

    let(:base_row) do
      { 'SKU' => uid, 'Title' => title, 'Description' => description, 'Price' => price, 'ShippingPrice' => shipping,
        'MSRP' => msrp, 'ProductImage1' => img1, 'ProductImage2' => img2, 'ProductImage3' => img3,
        'Category' => category, 'Condition' => condition }
    end
    let(:row) { base_row }
    subject { Sync::Listings::Ajm::ChannelAdvisorAdapter.new(row) }

    before do
      Sync::Listings::Ajm.stubs(:categories).returns({ :'Womens Accessories' => :accessories })
    end

    context "for a valid row of data" do
      its(:uid) { should == uid }
      its(:title) { should == title }
      its(:description) do
        should == "<ul><li><b>Retail Price</b>: $#{'%.2f' % msrp}</li></ul><ul><li>#{description}</li></ul>"
      end
      its(:price) { should == price }
      its(:shipping) { should == shipping }
      its(:category_slug) { should == 'accessories' }
      its(:condition) { should == 'New' }

      it "maps photo_urls to files" do
        Sync::Listings::Ajm::ImageFile.expects(:new).with(img1, '1').returns(:a)
        Sync::Listings::Ajm::ImageFile.expects(:new).with(img2, '2').returns(:b)
        Sync::Listings::Ajm::ImageFile.expects(:new).with(img3, '3').returns(:c)
        subject.photo_files.should == [:a, :b, :c]
      end

      context "with crappy mangled descriptions" do
        let(:description) { "One strapless shoulderOne long sleeveAsymmetric neckline" }

        its(:description) do
          should == "<ul><li><b>Retail Price</b>: $#{'%.2f' % msrp}</li></ul>" +
            "<ul><li>One strapless shoulder</li><li>One long sleeve</li><li>Asymmetric neckline</li></ul>"
        end
      end

      context "with duplicate tags and long tags" do
        let(:color) { 'Gun Metal' }
        let(:material) { 'Gun Metal' }
        let(:style) { 'Made in the classic style of bb guns the world over you will most definitely find it stylish.' }
        let(:row) { base_row.merge({ 'Style' => style, 'Color' => color, 'Material' => material }) }

        its(:tag_names) { should == ['Gun Metal'] }
      end

      context "with an unknown condition" do
        let(:condition) { 'WORN ONCE' }
        its(:condition) { should == 'Used' }
      end
    end
  end
end

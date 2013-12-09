require 'spec_helper'

describe DimensionValue do
  describe ".with_count_for_listings" do
    let :dimension do
      FactoryGirl.create(:dimension)
    end

    let :dimension_values do
      (0..3).map do
        FactoryGirl.create(:dimension_value, :dimension => dimension)
      end
    end

    let :listings do
      # ignore the first dimension value, so we can test
      # that dimensions with 0 listings won't show up
      values = dimension_values[1..-1]

      (0..4).map do |i|
        which_dimension_value = values.at(i % values.size)
        FactoryGirl.create(:incomplete_listing, category: dimension.category,
                           :dimension_values => [which_dimension_value])
      end
    end

    subject do
      dimension.values.with_count_for_listings(listings)
    end

    it "returns all tags with at least one element" do
      should have(dimension_values.size - 1).elements
    end

    it "retrieves the amount of listings with said tag" do
      val = lambda { |name| DimensionValue.find_by_value(name) }

      subject[dimension_values.at(0)].should == 0
      subject[dimension_values.at(1)].should == 2
      subject[dimension_values.at(2)].should == 2
      subject[dimension_values.at(3)].should == 1
    end

    it "rejects values passed in as exceptions" do
      values = dimension.values.with_count_for_listings(listings, [dimension_values.at(1).value])

      values.should_not have_key(dimension_values.at(1))
      values.should have_key(dimension_values.at(2))
    end
  end
end

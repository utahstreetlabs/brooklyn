require "spec_helper"

describe Dimension do
  it_should_behave_like "a sluggable model", :dimension

  describe ".grouped_with_values" do
    before do
      3.times do |i|
        dimension = FactoryGirl.create(:dimension)
        (i + 2).times { FactoryGirl.create(:dimension_value, :dimension => dimension) }
      end
    end

    it "returns a hash with all the dimensions" do
      dimensions = Dimension.grouped_with_values
      dimensions.should have(Dimension.count).keys
    end

    it "returns the values that each dimension has by default" do
      dimensions = Dimension.grouped_with_values
      dimensions.all? { |dimension, values| values == dimension.values }
    end

    it "uses the passed block to determine the associated values" do
      dimensions = Dimension.grouped_with_values { |values| values.map(&:id) }
      dimensions.all? { |dimension, values| values == dimension.values.map(&:id) }
    end

    it "passes the dimension itself to the block as a second argument" do
      Dimension.grouped_with_values do |values, dimension|
        dimension.values.should == values
      end
    end

    it "ignores any dimension that has an empty set of values" do
      some_dimension = Dimension.last
      some_dimension.values.destroy_all

      dimensions = Dimension.grouped_with_values
      dimensions.should_not have_key(some_dimension)
    end

    it "ignores any dimension that returns a non-#present? value from the block" do
      some_dimension = Dimension.last

      dimensions = Dimension.grouped_with_values do |values, dimension|
        dimension != some_dimension
      end
      dimensions.should_not have_key(some_dimension)
    end

    it "returns an empty hash if all dimensions return an empty set of values" do
      dimensions = Dimension.grouped_with_values { |values| [] }
      dimensions.should be_empty
    end
  end
end

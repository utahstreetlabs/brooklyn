require 'spec_helper'

class ABTestable
  include Brooklyn::ABTesting
end

describe Brooklyn::ABTesting do
  let(:experiments) { {} }
  before { Vanity.stubs(:playground).returns(stub('experiments', experiments: experiments)) }
  subject { ABTestable.new }

  describe "#latest_active_experiment" do
    describe "with one matching experiment" do
      let(:experiments) { {ham: :ham, zebras: :zebras, bacon: :bacon} }
      it "returns the key of the latest version of an experiment" do
        subject.latest_active_experiment(:ham).should == :ham
      end
    end

    describe "with multiple matching experiments" do
      let(:experiments) { {zebras: :zebras, bacon_v3: :bacon_v3, ham_v3: :ham_v3, ham: :ham, ham_v2: :ham_v2} }
      it "returns the key of the latest version of an experiment" do
        subject.latest_active_experiment(:ham).should == :ham_v3
      end
    end
  end
end

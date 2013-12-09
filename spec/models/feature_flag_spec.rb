require 'spec_helper'

describe FeatureFlag do
  describe "when disabling" do
    let(:flag) { FactoryGirl.build(:feature_flag, enabled: true, admin_enabled: true) }

    before do
      flag.persisted?.should be_false
      flag.save!
    end

    context "a user flag" do
      it "persists the change" do
        flag.update_attributes!(enabled: false)
        flag.reload
        flag.send(:enabled).should be_false
      end
    end

    context "an admin flag" do
      it "persists the change" do
        flag.update_attributes!(admin_enabled: false)
        flag.reload
        flag.send(:admin_enabled).should be_false
      end
    end
  end

  describe "when enabling" do
    let(:flag) { FactoryGirl.build(:feature_flag, enabled: false, admin_enabled: false) }

    before do
      flag.persisted?.should be_false
      flag.save!
    end

    context "a user flag" do
      it "persists the change" do
        flag.update_attributes!(enabled: true)
        flag.reload
        flag.send(:enabled).should be_true
      end
    end

    context "an admin flag" do
      it "persists the change" do
        flag.update_attributes!(admin_enabled: true)
        flag.reload
        flag.send(:admin_enabled).should be_true
      end
    end
  end
end

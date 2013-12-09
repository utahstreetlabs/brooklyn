require 'spec_helper'

describe Purchase do
  it { should normalize_attribute(:card_number).from(' 4111-1111 11111111 ').to('4111111111111111') }

  describe 'expiration date' do
    it "accepts this month" do
      subject.expires_on = Date.today.at_beginning_of_month + 5
      subject.valid?
      subject.errors[:expires_on].should be_empty
    end

    it "accepts a future month" do
      subject.expires_on = Date.today + 1.year
      subject.valid?
      subject.errors[:expires_on].should be_empty
    end

    it "does not accept last month" do
      subject.expires_on = Date.today - 1.year
      subject.valid?
      subject.errors[:expires_on].should_not be_empty
    end
  end
end

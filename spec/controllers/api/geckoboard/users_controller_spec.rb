require 'spec_helper'

describe Api::Geckoboard::UsersController do
  let(:registered) { 4 }
  let(:previously_registered) { 3 }
  let(:guest) { 2 }
  let(:connected) { 1 }
  let(:states) { {'guest' => guest, 'connected' => connected, 'registered' => registered } }
  subject { JSON.parse(response.body)['item'] }

  before do
    @request.env["HTTP_AUTHORIZATION"] = "Basic " + Base64::encode64("#{Brooklyn::Application.config.api.token}:")
    @request.env["HTTP_CONTENT_TYPE"] = "application/xml"
  end

  context "#count" do
    before do
      User.expects(:registered).returns(stub_everything('registered user scope', count: registered))
      User.expects(:registered_before).returns(stub_everything('previous registered user scope',
        count: previously_registered))
      get :count, format: :json
    end

    it { should have(2).values }
    it { should == [{'text' => '', 'value' => registered}, {'text' => '', 'value' => previously_registered}] }
  end

  context "#states" do
    before do
      User.expects(:count_by_state).returns(states)
      get :states, format: :json
    end
    it { should have(3).values }
    it { should == states.map { |k,v| {'text' => k, 'value' => v} } }
  end

  context "#registrations" do
    let(:regs) { 9.downto(0).inject({}) { |hash,i| hash[i.days.ago.to_date] = i; hash } }
    before do
      User.expects(:registrations_by_day).returns(regs)
      get :registrations, format: :json
    end
    it { should have(10).values }
    it { should == 9.downto(0).to_a }
  end
end

require 'spec_helper'

describe Network do
  describe '#known' do
    it "returns all known networks" do
      known_networks = Network.known
      known_networks.should include(:twitter)
      known_networks.should include(:facebook)
      known_networks.should_not include(:unknown_network)
    end
  end

  describe '#active' do
    it "returns all active networks" do
      active_networks = Network.active
      active_networks.should include(:twitter)
      active_networks.should include(:facebook)
      active_networks.should_not include(:unknown_network)
    end
  end

  describe '#registerable' do
    it "returns all registerable networks" do
      registerable_networks = Network.registerable
      registerable_networks.should include(:twitter)
      registerable_networks.should include(:facebook)
      registerable_networks.should_not include(:unknown_network)
    end
  end

  describe '#klass' do
    it "returns the class for a symbol" do
      require 'network/facebook'
      Network.klass(:facebook).should == Network::Facebook
    end

    it "raises an error for an unknown symbol" do
      expect { Network.klass(:myspace) }.to raise_error(NameError)
    end
  end
end

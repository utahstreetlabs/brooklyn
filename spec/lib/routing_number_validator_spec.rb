require 'spec_helper'

describe RoutingNumberValidator do
  describe '.valid_routing_number?' do
    subject { RoutingNumberValidator.new(attributes: [:routing_number]) }

    it 'rejects a too short string' do
      subject.valid_routing_number?('63100277').should be_false
    end

    it 'rejects a too long string' do
      subject.valid_routing_number?('0631002770').should be_false
    end

    it 'rejects a string with non-digit character' do
      subject.valid_routing_number?('o63100277').should be_false
    end

    it 'rejects a number that checksums incorrectly' do
      subject.valid_routing_number?('063100278').should be_false
    end

    it 'accepts a number that checksums correctly' do
      subject.valid_routing_number?('063100277').should be_true
    end
  end
end

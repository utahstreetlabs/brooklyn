require 'spec_helper'

class I18nable
  include Brooklyn::I18n
end

describe Brooklyn::I18n do
  subject { I18nable.new }

  context 'when data is not a/b test data' do
    it 'returns the given value' do
      expect(subject.ab_test_copy('clams')).to eq('clams')
    end
  end

  context 'when data is a/b test data' do
    let(:human) { 'human' }
    let(:centipede) { 'centipede' }
    let(:default) { 'human centipede' }
    let(:experiment) { :human_centipede }
    let(:variants) { {human: human, centipede: centipede, default: default} }
    let(:i18n_data) { {ab: {experiment => variants} } }
    let(:feature_enabled) { true }
    before do
      subject.expects(:feature_enabled?).with("experiments.#{experiment}").returns(feature_enabled)
    end

    context 'when the feature is enabled' do
      it 'looks up a value based on the ab_test variant' do
        subject.expects(:ab_test).returns(:human)
        expect(subject.ab_test_copy(i18n_data)).to eq(human)
      end
    end

    context 'when the feature is disabled' do
      let(:feature_enabled) { false }
      it 'looks up a default value' do
        expect(subject.ab_test_copy(i18n_data)).to eq(default)
      end

      context 'if there is no default value' do
        let(:default) { nil }
        it 'gets the value of the first variant' do
          expect(subject.ab_test_copy(i18n_data)).to eq(variants.values.first)
        end
      end
    end
  end
end

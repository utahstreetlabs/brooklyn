require 'spec_helper'

describe Network::Facebook::Ref do
  it 'should not accept non-hashes for data' do
    expect { new_ref('foo', 'bar') }.to raise_error(ArgumentError)
    expect { new_ref('foo', {}).data = '' }.to raise_error(ArgumentError)
  end

  it 'should return a hash of data by default' do
    new_ref('foo').data.should == {}
    ref = new_ref('foo')
    ref.data = nil
    ref.data.should == {}
  end

  it 'normalizes tag values from the initializer' do
    ref = new_ref('foo', {bar: :baz})
    ref.insights_tags.should == ['foo']
    ref = new_ref(['foo', 'faz'], {bar: :baz})
    ref.insights_tags.should == ['foo', 'faz']
  end

  it 'normalizes tag values from the setters' do
    ref = new_ref(nil, nil)
    ref.insights_tags = 'foo'
    ref.insights_tags.should == ['foo']
    ref.insights_tags = ['foo', 'faz']
    ref.insights_tags.should == ['foo', 'faz']
  end

  describe '#to_ref' do
    let(:i) { }
    let(:d) { }
    subject { new_ref(i, d).to_ref }

    context { it { should == nil } }
    context { let(:i) { 'foo' }; it { should == 'foo' } }
    context { let(:i) { ['foo'] }; it { should == 'foo' } }
    context { let(:i) { ['foo', 'bar'] }; it { should == 'foo,bar' } }
    context { let(:i) { [nil,nil] }; it { should == ',' } }
    context { let(:d) { {} }; it { should == nil }}
    context { let(:d) { {foo: :bar} }; it { should == '__' + b64('{"foo":"bar"}') }}
    context { let(:i) { ['foo', 'bar'] }; let(:d) { {fuz: :baz} }; it { should == 'foo,bar__' + b64('{"fuz":"baz"}')} }
    context { let(:i) { [nil, 'foo', nil, 'bar', nil] }; let(:d) { {fuz: nil} }; it { should == ',foo,,bar,__' + b64('{"fuz":null}') } }
  end

  describe '#from_ref' do
    let(:ref) { }
    subject do
      Network::Facebook::Ref.from_ref(ref)
    end

    context { it { should == new_ref([], nil) } }
    context { let(:ref) { '' }; it { should == new_ref([], nil) } }
    context { let(:ref) { 'foo' }; it { should == new_ref(['foo'], nil) } }
    context { let(:ref) { 'foo,bar' }; it { should == new_ref(['foo', 'bar'], nil) } }
    context { let(:ref) { '__' + b64('{}') }; it { should == new_ref([], {}) } }
    context { let(:ref) { 'foo,bar__' + b64('{"fuz": "baz"}') }; it { should == new_ref(['foo', 'bar'], {fuz: 'baz'}) } }
    context { let(:ref) { 'foo,,bar,__' + b64('{"fuz": "baz"}') }; it { should == new_ref(['foo', nil ,'bar', nil], {fuz: 'baz'}) } }
    context { let(:ref) { ',__' }; it { should == new_ref([nil, nil], nil) } }
    context { let(:ref) { '__asfjawlea' }; specify { expect { subject }.to raise_error(ArgumentError) } }
  end

  describe 'serialization and deserialization' do
    let(:ref_args) { }
    let(:ref) { new_ref(*ref_args) }
    subject { Network::Facebook::Ref.from_ref(ref.to_ref) }

    context { let(:ref_args) { [nil, {}] }; it { should == ref } }
    # this next one is a little weird, but it shouldn't be common, so I'm willing to live with it
    context { let(:ref_args) { [[nil], {}] }; it { should == new_ref([], {}) } }
    context { let(:ref_args) { [[nil, nil], {}] }; it { should == ref } }
    context { let(:ref_args) { ["hi", {}] }; it { should == ref } }
    context { let(:ref_args) { [:hi, {}] }; it { should == new_ref(["hi"], {}) } }
    context { let(:ref_args) { [["hi", "there"], {}] }; it { should == ref } }
    context { let(:ref_args) { [[:hi, :there], {}] }; it { should == new_ref(["hi", "there"], {}) } }
    context { let(:ref_args) { [[], {hi: "there"}] }; it { should == ref } }
    context { let(:ref_args) { [[], {hi: :there}] }; it { should == new_ref([], {hi: "there"}) } }
    context { let(:ref_args) { [[], {"hi" => "there"}] }; it { should == new_ref([], {hi: "there"}) } }
    context { let(:ref_args) { [[], {"hi" => :there}] }; it { should == new_ref([], {hi: "there"}) } }

  end

  def b64(s)
    Base64.urlsafe_encode64(s)
  end

  def new_ref(i, d = nil)
    Network::Facebook::Ref.new(i, d)
  end
end

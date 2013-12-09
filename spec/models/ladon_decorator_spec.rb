require 'spec_helper'

describe LadonDecorator do
  class Ladon::Nug < Ladon::Model
  end

  class Nug < LadonDecorator
    decorates Ladon::Nug
  end

  subject { Nug.new }

  describe '#initialize' do
    it 'should remember the provided model' do
      model = Ladon::Nug.new
      decorator = Nug.new(model)
      decorator.decorated.should == model
    end

    it 'should instantiate an empty model when none is provided' do
      decorator = Nug.new
      decorator.decorated.should be_a(Ladon::Nug)
    end

    it 'should raise an exception when record could not be saved' do
      Ladon::Nug.expects(:new).returns(nil)
      expect { Nug.new }.to raise_error(LadonDecorator::RecordNotSaved)
    end
  end

  describe '#update' do
    let(:id) { 'deadbeef' }
    let(:attrs) { {} }
    let(:updated) { Ladon::Nug.new }

    context 'when the subject has an id' do
      before do
        subject.id = id
        Ladon::Nug.expects(:update).with(id, is_a(Hash)).returns(updated)
      end

      it 'should decorate the provided attributes' do
        Nug.expects(:decorated_attributes).with(attrs).returns({})
        subject.update(attrs)
      end

      context 'and the update succeeds' do
        it 'should return true' do
          subject.update(attrs).should be_true
        end

        it 'should not have errors' do
          subject.update(attrs)
          subject.errors.should be_empty
        end
      end

      context 'and the update fails' do
        before { updated.errors.add(:foo, 'is invalid') }

        it 'should return false' do
          subject.update(attrs).should be_false
        end

        it 'should have errors' do
          subject.update(attrs)
          subject.errors.should_not be_empty
        end
      end
    end

    context 'when the subject does not have an id' do
      it 'should raise an exception' do
        expect { subject.update(attrs) }.to raise_error
      end
    end
  end

  describe '#all' do
    it 'should return decorated models' do
      count = 3
      nugs = (1..count).map {|i| Ladon::Nug.new}
      Ladon::Nug.expects(:all).returns(nugs)
      actual = Nug.all
      actual.should have(count).nugs
      (0..count-1).each do |i|
        actual[i].should be_a(Nug)
        actual[i].decorated.should == nugs[i]
      end
    end
  end

  describe '#find' do
    let(:id) { 123 }

    context 'when the model exists' do
      it 'should return the decorated model' do
        nug = Ladon::Nug.new
        Ladon::Nug.expects(:find).with(id).returns(nug)
        actual = Nug.find(id)
        actual.should be_a(Nug)
        actual.decorated.should == nug
      end
    end

    context 'when the model does not exist' do
      it 'should return nil' do
        Ladon::Nug.expects(:find).with(id).returns(nil)
        actual = Nug.find(id)
        actual.should be_nil
      end
    end
  end

  describe '#create' do
    let(:attrs) { {} }
    let(:created) { Ladon::Nug.new }

    before do
      Ladon::Nug.expects(:create).with(is_a(Hash)).returns(created)
    end

    it 'should decorate the provided attributes' do
      Nug.expects(:decorated_attributes).with(attrs).returns({})
      Nug.create(attrs)
    end

    context 'when the create succeeds' do
      it 'should return the decorated model' do
        actual = Nug.create(attrs)
        actual.should be_a(Nug)
        actual.decorated.should == created
      end

      it 'should not have errors' do
        actual = Nug.create(attrs)
        actual.errors.should be_empty
      end
    end

    context 'when the create fails' do
      before { created.errors.add(:foo, 'is invalid') }

      it 'should return the decorated model' do
        actual = Nug.create(attrs)
        actual.should be_a(Nug)
        actual.decorated.should == created
      end

      it 'should have errors' do
        actual = Nug.create(attrs)
        actual.errors.should_not be_empty
      end
    end
  end
end

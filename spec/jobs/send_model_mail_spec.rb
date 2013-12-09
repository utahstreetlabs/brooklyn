require "spec_helper"

describe SendModelMail do
  module SMM
    class Bar; end
    class Baz < Bar; end
    class Jam; end
    class Jaz < Jam; end
    class BarMailer; end
  end

  let (:bar) { stub('bar') }
  let (:bar2) { stub('bar') }

  it "should invoke a mailer to send email" do
    SMM::Bar.expects(:where).with(id: 1).returns([bar])
    SMM::BarMailer.expects(:drink).with(bar, bar2).returns(stub_everything)
    SendModelMail.perform('SMM::Bar', 'drink', 1, bar2)
  end

  it "doesn't send mail when the model instance does not exist" do
    SMM::Bar.expects(:where).with(id: 1).returns([])
    SMM::BarMailer.expects(:drink).never
    SendModelMail.perform('SMM::Bar', 'drink', 1, bar2)
  end

  describe "#find_mailer_class" do
    it 'should find the first superclass with a mailer or the mailer for this class' do
      SendModelMail.find_mailer_class(SMM::Bar).should == SMM::BarMailer
      SendModelMail.find_mailer_class(SMM::Baz).should == SMM::BarMailer
    end

    it 'should raise an error if no superclasses have a mailer' do
      expect{ SendModelMail.find_mailer_class(SMM::Jam) }.to raise_error(NameError)
      expect{ SendModelMail.find_mailer_class(SMM::Jaz) }.to raise_error(NameError)
    end
  end
end

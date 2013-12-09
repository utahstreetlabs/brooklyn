require 'spec_helper'

describe Notifications::BaseExhibit do
  let(:notification) { FactoryGirl.create(:notification) }

  class Notifications::Foo < Notifications::BaseExhibit; end
  class Notifications::Foo::BarBazExhibit < Notifications::Foo; end

  context ".factory" do
    it "renders a new notification" do
      notification.expects(:type).returns("FooBarBazNotification")
      Notifications::Foo::BarBazExhibit.expects(:new)
      Notifications::BaseExhibit.factory(notification)
    end

    it "catches the error when no exhibit exists" do
      notification.expects(:type).twice.returns("FooBarBazNotification")
      Notifications::Foo::BarBazExhibit.expects(:new).raises(NameError)
      expect { Notifications::BaseExhibit.factory(notification) }.to_not raise_exception
    end
  end
end

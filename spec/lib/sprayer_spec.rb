require 'spec_helper'

describe Brooklyn::Sprayer do
  class TestSprayer
    include Brooklyn::Sprayer
  end

  subject { TestSprayer }

  describe '#send_email' do
    it 'enqueues a SendModelMail job' do
      model = User.new
      model.id = 123
      extras = {foo: :bar}
      SendModelMail.expects(:enqueue).with(User.name, 'welcome_1', 123, has_entries(extras))
      subject.send_email(:welcome_1, model, extras)
    end
  end
end

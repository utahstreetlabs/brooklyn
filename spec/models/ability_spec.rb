require 'spec_helper'

describe Ability do
  # it's only worth testing the exceptions. a superuser can do anything, but an admin can't.

  context 'a superuser' do
    subject { Ability.new(stub('user', admin?: true, superuser?: true)) }

    it { should be_able_to(:create, User) }
    it { should be_able_to(:read, User.new) }
    it { should be_able_to(:update, User.new) }
    it { should be_able_to(:deactivate, User.new) }
  end

  context 'an admin' do
    subject { Ability.new(stub('user', admin?: true, superuser?: false)) }

    it { should_not be_able_to(:create, User) }
    it { should be_able_to(:read, User.new) }
    it { should be_able_to(:update, User.new) }
    it { should be_able_to(:deactivate, User.new) }
  end
end

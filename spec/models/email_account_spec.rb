require 'spec_helper'

describe EmailAccount do
  context "when loading contacts from janrain / rpx" do
    subject { FactoryGirl.create(:email_account, :user => FactoryGirl.create(:registered_user)) }
    let(:default_email) { 'the-default-janrain@test.com' }

    let(:matching_email) { default_email }
    let(:matching_user) { FactoryGirl.create(:registered_user, :email => matching_email) }
    let(:matching_unregistered_user) { FactoryGirl.create(:connected_user, :email => matching_email) }
    let(:matching_email_account) do
      FactoryGirl.create(:email_account, :email => matching_email, :user => FactoryGirl.create(:registered_user))
    end

    let(:contact_data) do
      [{
        'name' => { 'givenName' => 'Test', 'familyName' => 'User', 'formatted' => 'Test User' },
        'displayName' => 'Tester',
        'emails' => [default_email]
      }]
    end

    it "should prefer name.formatted over displayName" do
      subject.sync_contacts_from_data(contact_data)
      subject.contacts.first.fullname.should == 'Test User'
    end

    it "should use displayName when there is no name object" do
      data = contact_data.map { |entry| entry.reject { |k,v| k == 'name' } }
      subject.sync_contacts_from_data(data)
      subject.contacts.first.fullname.should == 'Tester'
    end

    it "should store multiple email addresses if found" do
      data = contact_data.map { |entry| entry['emails'] << 'test2@test.com'; entry }
      subject.sync_contacts_from_data(data)
      subject.contacts.first.email.should == default_email
      subject.contacts.last.email.should == 'test2@test.com'
    end

    it "should update existing contacts" do
      FactoryGirl.create(:contact, :email_account => subject, :email => default_email, :firstname => 'Testy')
      subject.sync_contacts_from_data(contact_data)
      subject.contacts.should have(1).contact
      subject.contacts.first.firstname.should == 'Test'
    end

    it "should follow user that matches email" do
      followee = matching_user
      subject.sync_contacts_from_data(contact_data)
      subject.user.followees.should have(1).followee
      subject.user.followees.first.should == followee
    end

    it "should follow user that matches email account" do
      followee = matching_email_account.user
      subject.sync_contacts_from_data(contact_data)
      subject.user.followees.should have(1).followee
      subject.user.followees.first.should == followee
    end

    it "should update person to that of matched user" do
      user = matching_email_account.user
      subject.sync_contacts_from_data(contact_data)
      subject.contacts.first.person.should == user.person
    end

    it "should fail silently when duplicating existing follow" do
      followee = matching_user
      subject.sync_contacts_from_data(contact_data)
      subject.sync_contacts_from_data(contact_data)
      subject.user.followees.should have(1).followee
      subject.user.followees.first.should == followee
    end

    it "should not follow user that has not completed registration" do
      followee = matching_unregistered_user
      subject.sync_contacts_from_data(contact_data)
      subject.user.followees.should have(:no).followees
    end

    it "should not follow user that matches own email" do
      self_account = FactoryGirl.create(:email_account, :user => matching_user)
      self_account.sync_contacts_from_data(contact_data)
      self_account.user.followees.should have(:no).followees
    end

    it "should not follow user that matches own account email" do
      matching_email_account.sync_contacts_from_data(contact_data)
      matching_email_account.user.followees.should have(:no).followees
    end

    context "#sync_contacts!" do
      let(:account) { FactoryGirl.create(:email_account, :user => FactoryGirl.create(:registered_user)) }

      context "when successful" do
        before do
          RPXNow.expects(:contacts).returns(contact_data)
          account.sync_contacts!
        end

        describe :sync_state do
          subject { account.sync_state }
          it { should == 'complete' }
        end
      end

      context "when unsuccessful" do
        before do
          RPXNow.expects(:contacts).raises(Exception, "janrain exception")
        end

        it "doesn't consume exception" do
          expect { account.sync_contacts! }.to raise_error("janrain exception")
        end

        describe :sync_state do
          subject { account.sync_state }
          before do
            begin
              account.sync_contacts!
            rescue Exception => e
              # pass
            end
          end

          it { should == 'error' }
        end
      end
    end

    context "when importing from windows live" do
      let(:token) { 'abcdefg' }
      let(:user) { FactoryGirl.create(:registered_user) }
      subject { EmailAccount.get_or_create_with_user_and_token(user, token) }

      before { RPXNow.expects(:user_data).with(token).returns(WINDOWS_LIVE_DATA) }

      it "should get the right email from windows live" do
        subject.email.should == "utahstreet@live.com"
      end

      it "should get the right identifier from windows live" do
        subject.identifier.should == "http://cid-c85e06e45d0e5d7f.spaces.live.com/"
      end

      it "should get the right provider from windows live" do
        subject.provider.should == "Windows Live"
      end
    end
  end

  context "#unregistered_contacts" do
    # this method uses custom sql, so db access mandatory
    let!(:account) { FactoryGirl.create(:email_account) }
    let!(:user) { FactoryGirl.create(:registered_user) }
    let!(:registered_contact) { FactoryGirl.create(:contact, person: user.person, email_account: account) }
    let!(:unregistered_contact) { FactoryGirl.create(:contact, email_account: account) }

    it "only returns contacts not associated with registered users" do
      contacts = account.unregistered_contacts
      contacts.should have(1).contact
      contacts.first.should == unregistered_contact
    end
  end
end

WINDOWS_LIVE_DATA = {
  :name => { "givenName" => "Robert", "familyName" => "Zuber", "formatted" => "Robert Zuber"},
  :displayName => "Robert",
  :providerName => "Windows Live",
  :identifier => "http://cid-c85e06e45d0e5d7f.spaces.live.com/",
  :email => "utahstreet@live.com"
}

require 'spec_helper'

describe Contact do
  context "#display_name" do
    context "with fullname" do
      let(:fullname) { 'Geddy Lee' }
      subject { Contact.new(fullname: fullname) }

      it "returns display_name using fullname" do
        subject.display_name.should == fullname
      end
    end

    context "with firstname only" do
      let(:firstname) { 'Alex' }
      subject { Contact.new(firstname: firstname) }

      it "returns display_name using firstname only" do
        subject.display_name.should == firstname
      end
    end

    context "with lastname only" do
      let(:lastname) { 'Lifeson' }
      subject { Contact.new(lastname: lastname) }

      it "returns display_name using lastname only" do
        subject.display_name.should == lastname
      end
    end

    context "with firstname and lastname but no fullname" do
      let(:firstname) { 'Alex' }
      let(:lastname) { 'Lifeson' }
      subject { Contact.new(firstname: firstname, lastname: lastname) }

      it "returns display_name using '<firstname> <lastname>'" do
        subject.display_name.should == "#{firstname} #{lastname}"
      end
    end

    context "with email only" do
      let(:email) { 'neil.peart@example.com' }
      subject { Contact.new(email: email) }

      it "returns display_name using the localpart of email" do
        subject.display_name.should == "neil.peart"
      end
    end
  end

  context "#associate_with_person!" do
    # couldn't get these association tests to work without saved models in db.
    let(:person) { FactoryGirl.create(:registered_user).person }
    let!(:contact) { FactoryGirl.create(:contact) }
    let!(:old_person_id) { contact.person_id }

    before do
      contact.associate_with_person!(person)
    end

    context "normally" do
      describe :person do
        subject { contact.person }
        it { should == person }
      end

      it "removes the orphaned person" do
        expect { Person.find(old_person_id) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when attempting to associate with the user with which it is already associated" do
      it "doesn't modify a contact already associated with the requested user" do
        contact.expects(:person=).never
        contact.associate_with_person!(person)
      end
    end

    context "when attempting to associate with a new user while already pointing to an existing user" do
      let(:person2) { FactoryGirl.create(:registered_user).person }

      before do
        contact.associate_with_person!(person2)
      end

      describe :new_person do
        subject { contact.person }
        it { should == person2 }
      end

      describe :old_person do
        subject { person }
        it { should be }
        it { should_not == contact.person }
      end
    end
  end

  context "#find_by_ids_with_email_accounts" do
    let(:account) { FactoryGirl.create(:email_account) }
    let!(:contact1) { FactoryGirl.create(:contact, email_account: account) }
    let!(:contact2) { FactoryGirl.create(:contact, email_account: account) }
    let(:contacts) { Contact.find_by_ids_with_email_accounts([contact1.id, contact2.id]) }

    context "returns the correct contacts" do
      describe 'contacts.first' do
        subject { contacts.first }
        it { should == contact1 }
      end

      describe 'contacts.last' do
        subject { contacts.last }
        it { should == contact2 }
      end
    end
  end
end

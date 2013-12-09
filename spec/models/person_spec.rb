require 'spec_helper'

describe Person do
  it "is not registered without a registered user" do
    person = FactoryGirl.build(:person)
    user = FactoryGirl.build(:connected_user)
    person.registered?.should be_false
  end

  it "is registered when it has a registered user" do
    person = FactoryGirl.create(:person)
    user = FactoryGirl.create(:registered_user, :person => person)
    person.registered?.should be_true
  end

  describe "update_oauth_token" do
    let(:profile) { stub('profile', id: 5555, person_id: subject.id, token: 'CAFEBEBE') }
    let(:new_token) { 'DEADBEEF' }

    it "updates token attribute when necessary" do
      subject.expects(:for_network).with(:facebook).returns(profile)
      profile.expects(:update_attributes!).with(token: new_token)
      profile.expects(:valid_credentials?).returns(true)
      subject.update_oauth_token(:facebook, token: new_token)
    end

    it "does not update token attribute if there is no profile for network" do
      subject.expects(:for_network).with(:facebook).returns(nil)
      profile.expects(:update_attributes!).never
      profile.expects(:valid_credentials?).never
      subject.update_oauth_token(:facebook, token: new_token)
    end

    it "does not update token attribute if it's valid but the same as existing" do
      subject.expects(:for_network).with(:facebook).returns(profile)
      profile.expects(:valid_credentials?).returns(false)
      profile.expects(:update_attributes!).never
      subject.update_oauth_token(:facebook, token: profile.token)
    end

    it "does not update token attribute if it is invalid" do
      subject.expects(:for_network).with(:facebook).returns(profile)
      profile.expects(:valid_credentials?).returns(false)
      profile.expects(:update_attributes!).never
      subject.update_oauth_token(:facebook, token: new_token)
    end
  end

  describe "#find_or_create_from_uid_and_network" do
    let(:oauth) { oauth_hash }
    let(:uid) { oauth_hash['uid'] }
    let(:network) { :facebook }
    let(:person) { stub('person', id: 123) }

    before do
      person.expects(:create_or_update_profile_from_oauth).with(network, oauth)
    end

    it "creates new person when the profile doesn't exist" do
      Rubicon::Profile.expects(:find_for_uid_and_network).with(uid, network).returns(nil)
      Person.expects(:create!).returns(person)
      new_person = find_or_create
      new_person.should == person
    end

    it "returns existing person when profile exists" do
      profile = stub('profile', person_id: person.id)
      Rubicon::Profile.expects(:find_for_uid_and_network).with(uid, network).returns(profile)
      Person.expects(:find).with(person.id).returns(person)
      find_or_create.should == person
    end

    def find_or_create
      Person.find_or_create_from_uid_and_network(uid, network, oauth)
    end
  end

  describe "missing_required_network_permissions" do
    let(:person) { FactoryGirl.build(:person) }

    before do
      Network.expects(:active).returns([:facebook])
      Network::Facebook.expects(:required_permissions).returns([:email])
    end

    context "when profile has all required permissions" do
      before do
        profile = stub('profile', scope: 'email')
        person.expects(:for_network).returns(profile)
        profile.expects(:has_permission?).returns(true)
      end

      it "returns an empty array" do
        person.missing_required_network_permissions.should == []
      end
    end

    context "when profile is missing a required permission" do
      before do
        profile = stub('profile', scope: 'email')
        person.expects(:for_network).returns(profile)
        profile.expects(:has_permission?).returns(false)
      end

      it "returns the list of missing permissions" do
        person.missing_required_network_permissions.should == [:facebook]
      end
    end
  end

  describe '#find_by_network_id' do
    let(:network_id) { 'network-id' }

    [:facebook, :twitter, :tumblr].each do |network|
      it "should call to rubicon for #{network}" do
        person = stub('person', id: 12345)
        Rubicon::Profile.expects(:find_for_uid_and_network).with(network_id, network).
          returns(stub('profile', person_id: person.id))
        Person.expects(:find).with(person.id).returns(person)
        Person.find_by_network_id(network_id, network).should == person
      end
    end
  end

  describe '#connect_from_oauth' do
    let(:network) { :facebook }
    let(:oauth) { oauth_hash }
    let(:person) { FactoryGirl.create(:person) }
    let(:user) { FactoryGirl.create(:registered_user, :person => person) }

    context "for a connected user" do
      it "succeeds" do
        person.stubs(:user).returns(user)
        Person.expects(:find_by_network_id).returns(person)
        Person.expects(:find_or_create_from_uid_and_network).never
        person.expects(:create_user_from_network_profile).never
        person.expects(:create_or_update_profile_from_oauth)
        Person.connect_from_oauth(network, oauth)
      end
    end

    context "when a person does not exist" do
      it "succeeds" do
        Person.expects(:find_by_network_id).returns(nil)
        Person.expects(:find_or_create_from_uid_and_network).returns(person)
        Person.connect_from_oauth(network, oauth)
      end
    end
  end

  describe '#network_profiles' do
    let(:twitter1) { stub('twitter1', network: :twitter, connected?: true, type: nil, to_ary: nil) }
    let(:twitter2) { stub('twitter2', network: :twitter, connected?: false, type: nil, to_ary: nil) }
    let(:tumblr) { stub('tumblr', network: :tumblr, connected?: true, type: nil, to_ary: nil) }

    before { Profile.stubs(:find_all_for_person).returns([twitter1, twitter2, tumblr]) }

    it 'prefers connected networks' do
      subject.network_profiles[:twitter].should == twitter1
    end
  end

  describe '#connected_networks' do
    it "returns connected networks" do
      twitter = stub('twitter', connected?: true)
      tumblr = stub('tumblr', connected?: false)
      subject.stubs(:network_profiles).returns(twitter: twitter, tumblr: tumblr)
      subject.connected_networks.should include(:twitter)
    end
  end

  describe '#connected_profiles' do
    it "returns only connected profiles" do
      twitter = stub('twitter', connected?: true)
      twitter.stubs(:to_ary).returns([twitter])
      tumblr = stub('tumblr', connected?: false)
      tumblr.stubs(:to_ary).returns([tumblr])
      subject.stubs(:network_profiles).returns(twitter: twitter, tumblr: tumblr)
      subject.connected_profiles.should include(twitter)
    end
  end

  describe '#minimally_connected' do
    let(:twitter) { stub('twitter', type: nil, connection_count: twitter_ccount, fetch_api_followers: []) }
    let(:tumblr) { stub('tumblr', type: nil, connection_count: tumblr_ccount, fetch_api_followers: []) }
    let(:minimum) { 5 }
    let(:twitter_ccount) { 0 }
    let(:tumblr_ccount) { 0 }

    before { subject.stubs(:connected_profiles).returns([twitter, tumblr]) }

    context "when connection count < minimum" do
      it "returns true when a profile has the minimum number of followers" do
        twitter.fetch_api_followers.expects(:count).returns(minimum * 2)
        subject.minimally_connected?(minimum).should be_true
      end

      it "returns false when no profile has the minimum number of followers" do
        subject.minimally_connected?(minimum).should be_false
      end
    end

    context "when connection count > minimum" do
      let(:twitter_ccount) { minimum * 2 }

      it "returns true" do
        subject.minimally_connected?(minimum).should be_true
      end

      it "doesn't call fetch_api_followers" do
        twitter.expects(:fetch_api_followers).never
        subject.minimally_connected?(minimum).should be_true
      end

      it "stops on the first valid network" do
        tumblr.expects(:connection_count).never
        subject.minimally_connected?(minimum).should be_true
      end
    end

    context "when an external service connection causes an exception" do
      let(:exception) { Exception.new("ruh-roh") }
      before { twitter.expects(:fetch_api_followers).raises(exception) }

      context "and permit_on_error is not set" do
        it "raises that exception " do
          expect { subject.minimally_connected?(minimum) }.to raise_exception(exception)
        end
      end

      context "and permit_on_error is true" do
        it "returns true" do
          subject.minimally_connected?(minimum, permit_on_error: true).should be_true
        end
      end
    end
  end

  it "finds the highest value network profile" do
    etsy = stub('etsy', connection_count: 1999, connected?: true)
    twitter = stub('twitter', connection_count: 158, connected?: true)
    tumblr = stub('tumblr', connection_count: 23, connected?: true)
    subject.stubs(:network_profiles).returns(twitter: twitter, tumblr: [tumblr], etsy: etsy)
    other = stub(connected_networks: [:etsy])
    subject.find_highest_value_network_profile(other).should == twitter
  end

  it "doesn't find a highest value network profile when both people are connected to the same networks" do
    networks = [:etsy, :twitter, :tumblr]
    other = stub(connected_networks: networks)
    subject.stubs(connected_networks: networks)
    subject.find_highest_value_network_profile(other).should be_nil
  end

  it "doesn't find a highest value network profile when the subject is not connected to any networks" do
    other = stub(connected_networks: [:etsy, :twitter, :tumblr])
    subject.stubs(connected_networks: [])
    subject.find_highest_value_network_profile(other).should be_nil
  end

  it "doesn't find a highest value network profile when the subject's networks have no followers" do
    twitter = stub('twitter', connection_count: 0, connected?: true)
    subject.stubs(:network_profiles).returns(twitter: twitter)
    other = stub(connected_networks: [])
    subject.find_highest_value_network_profile(other).should be_nil
  end

  describe "#invite_suggestions" do
    let(:person) { FactoryGirl.create(:person) }

    context "when facebook profile does not exist" do
      before do
        subject.stubs(:for_network).returns(nil)
      end
    end

    context "when facebook profile exists" do
      let(:profile) do
        stub('profile', id: '4e680eec50a79914b223456', network: 'facebook', name: 'Jay-Z')
      end

      before do
        subject.stubs(:for_network).returns(profile)
      end

      context "when not connected to facebook" do
        before do
          profile.stubs(:connected?).returns(false)
        end
      end

      context "when connected to facebook" do
        before do
          profile.stubs(:connected?).returns(true)
        end

        let(:suggestion) { stub('suggestion', person_id: 5555, id: 6666) }

        it "returns suggestions when we receive desired number" do
          suggestions = create_suggestions(3)
          subject.expects(:fetch_suggestions).with(profile, is_a(Integer), {num_suggestions: 3}).returns(suggestions)
          subject.invite_suggestions.should have(3).items
        end

        it "returns suggestions when not enough are returned on the first query" do
          suggested = states('suggested').starts_as('no')
          suggestions = create_suggestions(3)
          subject.stubs(:invite_suggestion_blacklist).returns([])
          profile.expects(:uninvited_followers).when(suggested.is('no')).returns(suggestions.take(3)).then(suggested.is('yes'))
          profile.expects(:uninvited_followers).when(suggested.is('yes')).returns(suggestions.take(1)).then(suggested.is('done'))
          subject.fetch_suggestions(profile, 3, num_suggestions: 4).should have(4).items
        end

        it "returns suggestions when none are returned after first query" do
          suggested = states('suggested').starts_as('no')
          subject.stubs(:invite_suggestion_blacklist).returns([])
          profile.expects(:uninvited_followers).when(suggested.is('no')).returns([]).then(suggested.is('yes'))
          profile.expects(:uninvited_followers).when(suggested.is('yes')).never
          subject.fetch_suggestions(profile, 3).should have(0).items
        end

        def create_suggestions(number=3)
          (1..number).inject([]) do |m,n|
            m << suggestion
            m
          end
        end
      end
    end
  end

  describe "#invite!" do
    let(:inviter_profile) do
      stub('inviter-profile', id: '4e680eec50a79914b223456', network: 'facebook', uid: '1234', connected?: true,
        name: 'Jay-Z', first_name: 'Jay')
    end
    let(:invitee_profile) do
      stub('invitee-profile', id: '4e680eec50a79914b200006', network: 'facebook', uid: '1235', connected?: false,
        name: 'Kanye West', first_name: 'Kanye')
    end
    let(:invite) { stub('invite') }
    let(:invite_url) { "foobar" }
    let(:invite_url_generator) { lambda {|i| invite_url }}
    let(:user) { stub('user', firstname: 'test') }

    before do
      subject.stubs(:missing_required_permissions).returns([])
      subject.stubs(:user).returns(user)
    end

    it "invites a network profile" do
      Profile.expects(:find).with(invitee_profile.id).returns(invitee_profile)
      subject.expects(:for_network).with(invitee_profile.network).returns(inviter_profile)
      invitee_profile.expects(:create_invite_from).with(inviter_profile).returns(invite)
      invitee_profile.expects(:send_invitation_from).with(inviter_profile, invite, is_a(Hash)).returns(true)
      PersonObserver.expects(:after_invite_sent).with(subject, invitee_profile)
      subject.invite!(invitee_profile.id, invite_url_generator).should == invite
    end

    it "populates network options correctly" do
      I18n.stubs(:translate).returns("i18n")
      Network.stubs(:known?).returns(true)
      Network.config.facebook.stubs(:invite_with_credit).returns(stub('invite', picture: "picture", link: 'link', source: "source", type: "link"))
      Profile.expects(:find).with(invitee_profile.id).returns(invitee_profile)
      subject.expects(:for_network).with(invitee_profile.network).returns(inviter_profile)
      invitee_profile.expects(:create_invite_from).with(inviter_profile).returns(invite)
      expected_options = { message: "i18n", caption: "i18n", description: "i18n", picture: "picture", link: invite_url, name: "i18n", source: "source", type: "link", actions: '[{"name":"i18n","link":"foobar"}]' }
      invitee_profile.expects(:send_invitation_from).with(inviter_profile, invite, has_entries(expected_options)).returns(true)
      PersonObserver.expects(:after_invite_sent).with(subject, invitee_profile)
      subject.invite!(invitee_profile.id, invite_url_generator).should == invite
    end

    it "fails when inviting a nonexistent profile" do
      Rubicon::Profile.expects(:find).with(invitee_profile.id).returns(nil)
      subject.expects(:for_network).never
      invitee_profile.expects(:create_invite_from).never
      invitee_profile.expects(:send_invitation_from).never
      PersonObserver.expects(:after_invite_sent).never
      subject.invite!(invitee_profile.id, invite_url_generator).should be_nil
    end

    it "fails when inviting an already-connected profile" do
      Rubicon::Profile.expects(:find).with(invitee_profile.id).returns(invitee_profile)
      Identity.expects(:find_by_provider_id).with(invitee_profile.network, invitee_profile.uid).
        returns(stub('identity'))
      subject.expects(:for_network).never
      invitee_profile.expects(:create_invite_from).never
      invitee_profile.expects(:send_invitation_from).never
      PersonObserver.expects(:after_invite_sent).never
      subject.invite!(invitee_profile.id, invite_url_generator).should be_nil
    end

    it "fails when inviter does not have a profile for the invitee's network" do
      Identity.expects(:find_by_provider_id).with(invitee_profile.network, invitee_profile.uid).returns(nil)
      Rubicon::Profile.expects(:find).with(invitee_profile.id).returns(invitee_profile)
      subject.expects(:for_network).with(invitee_profile.network).returns(nil)
      invitee_profile.expects(:create_invite_from).never
      invitee_profile.expects(:send_invitation_from).never
      PersonObserver.expects(:after_invite_sent).never
      subject.invite!(invitee_profile.id, invite_url_generator).should be_nil
    end

    it "fails when inviter's profile is not connected" do
      Identity.expects(:find_by_provider_id).with(invitee_profile.network, invitee_profile.uid).returns(nil)
      inviter_profile.expects(:connected?).returns(false)
      Rubicon::Profile.expects(:find).with(invitee_profile.id).returns(invitee_profile)
      subject.expects(:for_network).with(invitee_profile.network).returns(inviter_profile)
      invitee_profile.expects(:create_invite_from).never
      invitee_profile.expects(:send_invitation_from).never
      PersonObserver.expects(:after_invite_sent).never
      subject.invite!(invitee_profile.id, invite_url_generator).should be_nil
    end

    it "fails when there is an error creating the invite" do
      Identity.expects(:find_by_provider_id).with(invitee_profile.network, invitee_profile.uid).returns(nil)
      Rubicon::Profile.expects(:find).with(invitee_profile.id).returns(invitee_profile)
      subject.expects(:for_network).with(invitee_profile.network).returns(inviter_profile)
      invitee_profile.expects(:create_invite_from).with(inviter_profile).returns(nil)
      invitee_profile.expects(:send_invitation_from).never
      PersonObserver.expects(:after_invite_sent).never
      subject.invite!(invitee_profile.id, invite_url_generator).should be_nil
    end

    it "fails when there is an error sending the invitation" do
      Identity.expects(:find_by_provider_id).with(invitee_profile.network, invitee_profile.uid).returns(nil)
      Rubicon::Profile.expects(:find).with(invitee_profile.id).returns(invitee_profile)
      subject.expects(:for_network).with(invitee_profile.network).returns(inviter_profile)
      invitee_profile.expects(:create_invite_from).with(inviter_profile).returns(invite)
      invitee_profile.expects(:send_invitation_from).with(inviter_profile, invite, is_a(Hash)).returns(false)
      PersonObserver.expects(:after_invite_sent).never
      subject.invite!(invitee_profile.id, invite_url_generator).should be_nil
    end
  end

  describe "#find_by_any_email" do
    let(:search_email) { "notusedbyfactories@example.com" }
    let(:user_email) { "notusedbyfactorieseither@example.com" }

    it "should find users by User.email" do
      FactoryGirl.create(:registered_user, :email => user_email)
      Person.find_by_any_email(user_email).user.email.should == user_email
    end

    it "should find users by EmailAccount.email" do
      user = FactoryGirl.create(:registered_user, :email => user_email)
      account = FactoryGirl.create(:email_account, :user => user, :email => search_email)
      Person.find_by_any_email(search_email).user.email.should == user_email
    end
  end

  describe "#eligible_for_facebook_timeline?" do
    let(:user) { FactoryGirl.create(:registered_user) }

    before do
      subject.stubs(:user).returns(user)
    end

    it "returns false if feature already disallowed" do
      subject.eligible_for_facebook_timeline?.should be_false
    end

    it "ignores disabled features with force option" do
      user.expects(:allow_feature?).never
      subject.eligible_for_facebook_timeline?(force_request: true)
    end

    context "when preferences allow the feature" do
      before do
        user.expects(:allow_feature?).with(:request_timeline_facebook).returns(true)
      end

      it "returns false if user not connected to facebook" do
        subject.expects(:for_network).with(:facebook).returns(nil)
        subject.eligible_for_facebook_timeline?.should be_false
      end

      context "when user is connected to facebook" do
        let(:profile) { stub('profile', person_id: subject.id) }

        before do
          subject.expects(:for_network).with(:facebook).returns(profile)
        end

        context "when permissions are missing locally" do
          before do
            profile.expects(:has_permission?).returns(false)
          end

          it "returns true if profile does not currently have publish_actions locally" do
            subject.eligible_for_facebook_timeline?.should be_true
          end
        end

        context "when permissions are present locally" do
          before do
            profile.expects(:has_permission?).returns(true)
          end

          it "returns false if timeout raised" do
            profile.expects(:has_live_permission?).with(:publish_actions).raises(Timeout::Error)
            subject.eligible_for_facebook_timeline?.should be_false
          end

          it "returns true if user does not currently allow publish_actions" do
            profile.expects(:has_live_permission?).with(:publish_actions).returns(false)
            subject.eligible_for_facebook_timeline?.should be_true
          end

          it "returns false if user currently allows publish_actions" do
            profile.expects(:has_live_permission?).with(:publish_actions).returns(true)
            subject.eligible_for_facebook_timeline?.should be_false
          end

          it "returns false if checking live permissions results in exception" do
            profile.expects(:has_live_permission?).with(:publish_actions).raises(Exception)
            subject.eligible_for_facebook_timeline?.should be_false
          end
        end
      end
    end
  end
end

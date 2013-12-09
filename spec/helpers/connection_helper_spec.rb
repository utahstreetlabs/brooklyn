require 'spec_helper'
require 'person_helper'

describe ConnectionHelper do
  include PersonHelper

  context "when listing detailed connections" do
    let(:adjacent) { stub_person('Adjacent Person') }
    let(:other) { stub_person('Other Person') }

    before do
      # helper.stubs(:person_avatar_small).returns('')
      # helper.stubs(:link_to_person_profile).returns('Other Person').then.returns('Adjacent Person')
      act_as_rfb(stub_user('Rilo Kiley'))
    end

    context "for a direct facebook connection" do
      let(:connection) { stub_connection([:facebook_friend]) }

      it "shows the correct description" do
        cl = helper.connection_list(connection, 3)
        cl.should have_content("Other Person is your Facebook friend")
      end
    end

    context "for a facebook friend following someone" do
      let(:connection) { stub_connection([:facebook_friend, :usl_follower]) }

      it "shows the correct description" do
        cl = helper.connection_list(connection, 3)
        cl.should have_content("Adjacent Person is following Other Person")
      end
    end

    context "for a followee following a facebook friend" do
      let(:connection) { stub_connection([:usl_follwer, :usl_follower, :facebook_friend]) }

      it "shows the correct description" do
        cl = helper.connection_list(connection, 3)
        cl.should have_content("Adjacent Person is following Other Person's friends")
      end
    end

    def stub_person(name)
      stub_everything('person', :registered? => true,
        :user => stub_everything(:name => name, :profile_photo => stub_everything(:url => 'http://blah')))
    end

    def stub_connection(*type_arrays)
      paths = type_arrays.map do |types|
        stub(:adjacent => stub_person("Adjacent Person"), :other => stub_person("Other Person"), :types => types,
          :direct? => types.length == 1)
      end
      stub(:paths => paths)
    end
  end
end

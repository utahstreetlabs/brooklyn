require 'spec_helper'

describe UsersHelper do
  let(:user1) { stub_user("Dimwit Flathead") }
  let(:user2) { stub_user("Loowit Flathead") }
  let(:user3) { stub_user("Mumberthrax Flathead") }
  let(:user4) { stub_user("Duncwit Flathead") }
  let(:trans_current) { I18n.t('helpers.users.current_user') }

  context "when aggregating profile links" do
    context "for a single user" do
      let(:users) { [user1] }

      context "when the user is the current user" do
        let(:current_user) { user1 }
        it "aggregates a single user" do
          aggregate_user_profile_names(users).should == link_to_user_profile(user1)
        end
      end

      context "when the user is not the current user" do
        let(:current_user) { user4 }
        it "aggregates a single user" do
          aggregate_user_profile_names(users).should == link_to_user_profile(user1)
        end
      end
    end

    context "for two users" do
      let(:users) { [user1, user2] }

      context "when one of the users is the current user" do
        let(:current_user) { user1 }

        it "aggregates two users" do
          aggregate_user_profile_names(users).should == "#{link_to_user_profile(user1)} and #{link_to_user_profile(user2)}"
        end

        it "sorts users" do
          aggregate_user_profile_names(users.reverse, {:sort_alpha => true}).should == "#{link_to_user_profile(user1)} and #{link_to_user_profile(user2)}"
        end

        it "puts current user first" do
          aggregate_user_profile_names(users.reverse, {:current_user_first => true}).should == "#{link_to_user_profile(user1)} and #{link_to_user_profile(user2)}"
        end

        it "summarizes after one user" do
          aggregate_user_profile_names(users, {:summarize_after => 1}).should == "#{link_to_user_profile(user1)} and 1 other"
        end

        it "does not summarize if the count is too high" do
          aggregate_user_profile_names(users, {:summarize_after => 2}).should == "#{link_to_user_profile(user1)} and #{link_to_user_profile(user2)}"
        end

        it "replaces current user with translation" do
          aggregate_user_profile_names(users, {:translate_current_user => true}).should == "#{link_to_user_profile(user1, {:text => trans_current})} and #{link_to_user_profile(user2)}"
        end
      end

      context "when one of the users is not the current user" do
        let(:current_user) { user4 }

        it "aggregates two users" do
          aggregate_user_profile_names(users).should == "#{link_to_user_profile(user1)} and #{link_to_user_profile(user2)}"
        end
      end
    end

    context "for more than two users" do
      let(:users) { [user1, user2, user3] }

      context "when one of the users is the current user" do
        let(:current_user) { user1 }

        it "aggregates three users" do
          aggregate_user_profile_names(users).should == "#{link_to_user_profile(user1)}, #{link_to_user_profile(user2)}, and #{link_to_user_profile(user3)}"
        end

        it "sorts users" do
          aggregate_user_profile_names(users.reverse, {:sort_alpha => true}).should == "#{link_to_user_profile(user1)}, #{link_to_user_profile(user2)}, and #{link_to_user_profile(user3)}"
        end

        it "puts current user first" do
          aggregate_user_profile_names(users.reverse, {:current_user_first => true}).should == "#{link_to_user_profile(user1)}, #{link_to_user_profile(user2)}, and #{link_to_user_profile(user3)}"
        end

        it "summarizes after one user" do
          aggregate_user_profile_names(users, {:summarize_after => 1}).should == "#{link_to_user_profile(user1)} and 2 others"
        end

        it "summarizes after two users" do
          aggregate_user_profile_names(users, {:summarize_after => 2}).should == "#{link_to_user_profile(user1)}, #{link_to_user_profile(user2)}, and 1 other"
        end

        it "does not summarize if the count is too high" do
          aggregate_user_profile_names(users, {:summarize_after => 3}).should == "#{link_to_user_profile(user1)}, #{link_to_user_profile(user2)}, and #{link_to_user_profile(user3)}"
        end

        it "replaces current user with translation" do
          aggregate_user_profile_names(users, {:translate_current_user => true}).should == "#{link_to_user_profile(user1, {:text => trans_current})}, #{link_to_user_profile(user2)}, and #{link_to_user_profile(user3)}"
        end

        it "summarizes, puts current user first, and translates" do
          aggregate_user_profile_names(users.reverse, {:translate_current_user => true, :current_user_first => true, :summarize_after => 2}).should == "#{link_to_user_profile(user1, {:text => trans_current})}, #{link_to_user_profile(user2)}, and 1 other"
        end
      end

      context "when one of the users is not the current user" do
        let(:current_user) { user4 }

        it "aggregates three users" do
          aggregate_user_profile_names(users).should == "#{link_to_user_profile(user1)}, #{link_to_user_profile(user2)}, and #{link_to_user_profile(user3)}"
        end
      end
    end
  end

  def logged_in?
    true
  end
end

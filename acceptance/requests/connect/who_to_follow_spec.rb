require './acceptance/spec_helper'

feature "Who To Follow" do
  let(:user) { given_registered_user email: 'extra@meat.org', name: "Meat Plate" }
  let!(:interesting_user) { given_registered_user email: 'spam@no-meat.org', name: "Vegan Spam" }
  #add interests/loves for user

  background do
    login_as 'jimmy@page.com'
    given_interests(1)
    given_interest_suggestions(current_user)
    given_interest_suggestions(user)
    given_interest_suggestions(interesting_user)
  end

  context "when visiting page" do
    background do
      visit connect_who_to_follow_index_path
    end

    it "user is presented with follows", js: true do
      expect(page).to have_follow_suggestions
      within_user_strip(user) do
        find(".hidden-phone #follow-button-#{user.id}").click
      end
      expect(user_strip(user)).to have_content('FOLLOWING')
    end

    it "user hides suggestion, it does not reappear on reload", js: true do
      within_user_strip(user) do
        find("[data-action=remove]").click
      end
      visit connect_who_to_follow_index_path
      expect(page).to_not have_content(user.name)
      expect(page).to have_content(interesting_user.name)
    end
  end

  def user_strip_id(user)
    "#user-strip-#{user.id}"
  end

  def user_strip(user)
    find(user_strip_id(user))
  end

  def within_user_strip(user, &block)
    within(user_strip_id(user), &block)
  end

  matcher :have_follow_suggestions do
    match do |page|
      page.has_css?("[data-role=user-strip]")
    end
  end
end

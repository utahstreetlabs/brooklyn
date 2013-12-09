require './acceptance/spec_helper'

feature "Manage user suggestion" do
  background do
    given_interests(3)
    given_global_interest
    login_as 'roslin@galactica.mil', admin: true
  end

  let!(:user) { given_registered_user }

  scenario 'adds user to suggested list', js: true do
    visit admin_user_path(user.id)
    expect(page).to_not have_all_interest_suggestions
    add_suggestions
    expect(page).to have_all_interest_suggestions
  end

  scenario 'removes user from suggested list', js: true do
    given_interest_suggestions(user)
    visit admin_user_path(user.id)
    expect(page).to have_all_interest_suggestions
    remove_suggestions
    expect(page).to_not have_all_interest_suggestions
  end

  def add_suggestions
    open_modal(modal_id)
    within_modal(modal_id) do
      page.all('input[type=checkbox]').each { |cb| cb.set(true) }
    end
    save_modal(modal_id)
    wait_a_sec_for_selenium
  end

  def remove_suggestions
    open_modal(modal_id)
    within_modal(modal_id) do
      page.all('input[type=checkbox]').each { |cb| cb.set(false) }
    end
    save_modal(modal_id)
    wait_a_sec_for_selenium
  end

  def modal_id
    :manage_suggestions
  end

  matcher :have_all_interest_suggestions do
    match do |page|
      Interest.all.all? do |interest|
        page.has_css?("[data-interest='#{interest.id}']")
      end
    end
  end
end

require './acceptance/spec_helper'

feature 'Feature flags' do
  background do
    login_as 'roslin@galactica.mil', admin: true
  end

  context "when changing user feature flags" do
    scenario 'enable', js: true do
      with_flag(enabled: false) do |flag|
        visit(admin_feature_flags_path)
        enable_flag(flag)
        flag_should_be_enabled(flag)
      end
    end

    scenario 'disable', js: true do
      with_flag(enabled: true) do |flag|
        visit(admin_feature_flags_path)
        disable_flag(flag)
        flag_should_be_disabled(flag)
      end
    end
  end

  context "when changing admin feature flags" do
    scenario 'enable', js: true do
      with_flag(admin_enabled: false) do |flag|
        visit(admin_feature_flags_path)
        enable_flag(flag, admin: true)
        flag_should_be_enabled(flag, admin: true)
      end
    end

    scenario 'disable', js: true do
      with_flag(admin_enabled: true) do |flag|
        visit(admin_feature_flags_path)
        disable_flag(flag, admin: true)
        flag_should_be_disabled(flag, admin: true)
      end
    end
  end

  # because we aren't truncating the feature flags table after every test in order to preserve the real feature
  # flags across test runs, we need to nuke the created flags
  def with_flag(attrs = {}, &block)
    # use a name that is guaranteed to show up on the first page
    flag = FactoryGirl.create(:feature_flag, attrs.reverse_merge(name: 'aaaaa'))
    begin
      yield flag
    ensure
      flag.destroy
    end
  end

  def enable_flag(flag, options = {})
    within_flag(flag, options) do
      page.find('[data-action=enable]').click
    end
  end

  def disable_flag(flag, options = {})
    within_flag(flag, options) do
      page.find('[data-action=disable]').click
    end
  end

  def flag_should_be_enabled(flag, options = {})
    within_flag(flag, options) do
      page.should have_selector('[data-action=disable]')
    end
  end

  def flag_should_be_disabled(flag, options = {})
    within_flag(flag, options) do
      page.should have_selector('[data-action=enable]')
    end
  end

  def within_flag(flag, options = {}, &block)
    type = options[:admin] ? 'admin' : 'user'
    within("#flag-#{flag.id}-#{type}-enabled", &block)
  end
end

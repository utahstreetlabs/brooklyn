require 'factory_girl_rails'
require 'jsend-rails/test/matchers'
require 'jsend-rails/test/response'

DEFAULT_PASSWORD = "test"

module ControllerHelpers
  def stub_facebook_profile_connection
    FacebookProfile.any_instance.stubs(:update_from_facebook)
    FacebookProfile.any_instance.stubs(:sync_friends!)
  end

  def act_as(user_or_id)
    id = user_or_id ? (user_or_id.is_a?(User) ? user_or_id.id : user_or_id) : nil
    user = user_or_id ? (user_or_id.is_a?(User) ? user_or_id : stub('user', id: id, registered?: true)) : nil
    session[:user_id] = id
    User.stubs(:with_person).with(id).returns(user)
    subject.stubs(:update_accessed).returns(true)
  end

  def act_as_stub_user(options = {})
    user = options[:user]
    unless user
      user = stub('current_user', {id: 123, slug: 'current-user', person_id: 124, name: 'Tester',
                  registered?: true}.merge(options[:stubs] || {}))
    end
    act_as(user.id)
    subject.stubs(:current_user).returns(user)
    user.stubs(:superuser?).returns(options[:superuser])
    user.stubs(:admin?).returns(user.superuser? || options[:admin])
    user.stubs(:remember_exists_and_not_expired?).returns(false)
    user.stubs(:person).returns(stub('person')) unless user.respond_to?(:person)
    user.stubs(:recent_notifications).returns([])
    user.stubs(:visitor_id).returns('hamburgler')
    if options[:connected]
      user.stubs(:registered?).returns(false)
      user.stubs(:connected?).returns(true)
    end
    user.stubs(:touch_last_accessed)
    user
  end

  def act_as_stub_api_consumer(options = {})
    token = 'abc123'
    user = act_as_stub_user(options)
    api_config = stub('api_config', user: user, token: token)
    format = "application/#{options.fetch(:format, :xml)}"
    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(token,'')
    request.env["HTTP_ACCEPT"] = format
    request.env["HTTP_CONTENT_TYPE"] = format
    ApiConfig.expects(:find_by_token).with(token, include: :user).returns(api_config)
    user
  end

  def login_cookie_set?
    session[:user_id].present?
  end

  def act_as_guest(user_or_id)
    session[:guest_id] = user_or_id ? (user_or_id.is_a?(User) ? user_or_id.id : user_or_id) : nil
  end

  def act_as_guest_user(options = {})
    user = options[:user] || stub('guest_user', id: 456, person_id: 456)
    act_as_guest(user.id)
    subject.stubs(:guest_user).returns(user)
    user
  end

  def guest?
    session[:guest_id].present?
  end

  def can(action, resource)
    subject.stubs(:authorize!).with(action, resource)
  end

  def be_redirected_to_home_page
    redirect_to(root_path)
  end

  def be_redirected_to_home_page_without_autologin
    redirect_to(controller: :home, action: :index, noal: true)
  end

  def be_redirected_to_dashboard
    redirect_to(dashboard_path)
  end
end

# Ensures that the response redirects to the signup page without considering the query string (which usually contains a
# destination parameter that is specific to each page).
RSpec::Matchers.define :be_redirected_to_auth_page do
  def to_path(response)
    URI(response.location).path
  end

  match do |response|
    response.redirect? && (to_path(response) == Rails.application.routes.url_helpers.signup_path)
  end

  failure_message_for_should do |actual|
    "expected #{response.redirect?} to be true and #{to_path(response)} to == #{Rails.application.routes.url_helpers.signup_path}"
  end
end

RSpec::Matchers.define :have_redirect do |name|
  match do |session|
    session.include?(ApplicationController.send(:redirect_key, name))
  end
end

RSpec::Matchers.define :have_filter do |name|
  match do |controller|
    subject._process_action_callbacks.map(&:filter).include?(:check_session_expiration)
  end
end

RSpec::Matchers.define :have_flash_message do |key, options|
  match do |actual|
    actual.should =~ /#{translate(key, options)}/
  end

  failure_message_for_should do |actual|
    "expected that '#{actual}' would include '#{translate(key, options)}'"
  end

  def translate(key, options)
    options ||= {}
    scope = options.delete(:scope)
    if scope.present?
      options[:scope] = "controllers.#{scope}" unless scope =~ /^controllers/
    else
      key = "controllers.#{key}" unless key =~ /^controllers/
    end
    I18n.translate(key, options)
  end
end

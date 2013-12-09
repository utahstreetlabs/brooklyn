module ViewHelpers
  def act_as(role, listing = nil)
    case role.to_sym
    when :anonymous then act_as_anonymous
    when :rfb then act_as_rfb
    when :buyer then act_as_buyer(listing)
    when :seller then act_as_seller(listing)
    else raise "Unknown role #{role}"
    end
  end

  def act_as_anonymous
    view.stubs(:logged_in?).returns(false)
    view.stubs(:anonymous_user?).returns(true)
    view.stubs(:current_user).returns(nil)
    view.stubs(:buyer?).returns(false)
    view.stubs(:seller?).returns(false)
    view.stubs(:admin?).returns(false)
  end

  def act_as_rfb(user = nil)
    view.stubs(:logged_in?).returns(true)
    view.stubs(:anonymous_user?).returns(false)
    view.stubs(:current_user).returns(user.nil?? FactoryGirl.create(:registered_user) : user)
    view.stubs(:update_accessed).returns(true)
    view.stubs(:buyer?).returns(false)
    view.stubs(:seller?).returns(false)
    view.stubs(:admin?).returns(false)
  end

  def act_as_buyer(listing)
    view.stubs(:logged_in?).returns(true)
    view.stubs(:anonymous_user?).returns(false)
    view.stubs(:current_user).returns(listing.buyer)
    view.stubs(:update_accessed).returns(true)
    view.stubs(:buyer?).returns(true)
    view.stubs(:seller?).returns(false)
    view.stubs(:admin?).returns(false)
  end

  def act_as_seller(listing)
    view.stubs(:logged_in?).returns(true)
    view.stubs(:anonymous_user?).returns(false)
    view.stubs(:current_user).returns(listing.seller)
    view.stubs(:update_accessed).returns(true)
    view.stubs(:buyer?).returns(false)
    view.stubs(:seller?).returns(true)
    view.stubs(:admin?).returns(false)
  end

  # DEPRECATED: move from embedding admin? checks in views to using can?
  def act_as_admin(user = nil)
    act_as_rfb(user)
    view.stubs(:admin?).returns(true)
  end

  def can(action, resource)
    view.stubs(:can?).with(action, resource).returns(true)
  end

  def cannot(action, resource)
    view.stubs(:can?).with(action, resource).returns(false)
  end
end

RSpec::Matchers.define :display_connection_count do |expected|
  match do |actual|
    actual.include?("#{expected} connection")
  end

  match_for_should_not do |actual|
    actual !~ /[0-5] connections?/
  end
end

RSpec::Matchers.define :display_facebook_friend_connection do |expected|
  match do |actual|
    actual.include?("is your Facebook friend")
  end
end

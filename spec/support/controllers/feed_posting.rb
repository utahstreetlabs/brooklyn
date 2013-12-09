shared_examples_for "an action that handles feed errors properly" do
  it "flashes alert when missing permissions" do
    exception_thrower.raises(MissingPermission)
    action
    response.should be_jsend_failure
    response.jsend_data['message'].should eq(I18n.t('controllers.profiles.error_missing_permission', link: "/auth/facebook?s=b"))
  end

  it "flashes alert when password has changed" do
    exception_thrower.raises(InvalidSession)
    action
    response.should be_jsend_failure
    response.jsend_data['message'].should eq(I18n.t('controllers.profiles.error_invalid_session', link: "/auth/facebook?s=b"))
  end

  it "flashes alert when friend does not allow wall post" do
    exception_thrower.raises(ActionNotAllowed)
    action
    response.should be_jsend_failure
    response.jsend_data['message'].should eq(I18n.t('controllers.profiles.error_action_not_allowed'))
  end

  it "flashes alert when we've hit the rate limit on wall posts" do
    exception_thrower.raises(RateLimited)
    action
    response.should be_jsend_failure
    response.jsend_data['message'].should eq(I18n.t('controllers.profiles.error_rate_limited_invite', network: "Facebook"))
  end

  it "flashes alert when our access token is invalid" do
    exception_thrower.raises(AccessTokenInvalid)
    action
    response.should be_jsend_failure
    response.jsend_data['message'].should eq(I18n.t('controllers.profiles.error_access_token_invalid', network: "Facebook", link: "/auth/facebook?s=b"))
  end

  it "returns an error for general exceptions" do
    exception_thrower.raises(Exception)
    action
    response.should be_jsend_error
  end
end

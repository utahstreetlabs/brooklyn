require 'spec_helper'

class ExpirableController < ApplicationController
  include Controllers::SessionExpirable
end

describe ExpirableController, type: :controller do
  it "adds expiration filter" do
    subject.should have_filter(:check_session_expiration)
  end

  context "#check_session_expiration" do
    it "forgets and raises for an expired session" do
      subject.expects(:session_expired?).once.returns(true)
      subject.send(:current_user).expects(:forget_me!).once
      lambda { subject.check_session_expiration do; end }.should raise_error(Controllers::SessionExpired)
      session[:expires_at].should be_nil
    end

    it "yields and touches unexpired session" do
      session[:expires_at].should be_nil
      subject.expects(:session_expired?).once.returns(false)
      subject.send(:current_user).expects(:forget_me!).never
      lambda { subject.check_session_expiration do; end }.should_not raise_error
      session[:expires_at].should be
    end
  end
end

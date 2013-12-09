class Admin::Scores::InterestsController < ApplicationController
  include Controllers::AdminScoped

  def index
    @user = User.find(params[:user_id]) if params[:user_id]
    @user ||= current_user
    start_time = Time.now
    @interest_scores = @user.interest_scores
    end_time = Time.now
    @time = ((end_time - start_time) * 1000)
  end
end

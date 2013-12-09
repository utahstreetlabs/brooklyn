class Settings::PhotosController < ApplicationController
  include Controllers::Jsendable

  respond_to :json

  def update
    current_user.profile_photo = params[:user][:profile_photo]
    save_and_render_photo
  end

  def create
    current_user.profile_photo.download_from_network!(params[:network])
    save_and_render_photo
  end

protected

  def save_and_render_photo
    if current_user.save
      respond_with_jsend success: {result: render_to_string(partial: '/settings/profile/photo.html')}
    else
      respond_with_jsend error: 'Bad Request', code: 400, data: {errors: current_user.errors}
    end
  end
end

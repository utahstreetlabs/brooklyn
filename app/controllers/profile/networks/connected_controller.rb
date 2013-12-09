class Profile::Networks::ConnectedController < ApplicationController

  skip_requiring_login_only

  def show
    networks = (params[:networks] || []).map(&:to_sym)
    connected_to = networks.each_with_object({}) { |n, c| c[n] = current_user.connected_to?(n) }

    respond_to do |format|
      format.json do
        render_jsend(success: { networks: connected_to })
      end
    end
  end
end



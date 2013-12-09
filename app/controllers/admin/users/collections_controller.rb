class Admin::Users::CollectionsController < ApplicationController
  layout 'admin'

  load_and_authorize_resource :user

  def index
    authorize! :index, Collection
    @collections = Collection.where(user_id: params[:user_id])
    @collections = @collections.datagrid(params, includes: [:autofollows, :user])
  end
end

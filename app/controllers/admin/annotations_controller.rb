class Admin::AnnotationsController < ApplicationController
  include Controllers::AdminScoped

  layout 'admin'
  set_flash_scope 'admin.annotations'
  load_resource
  before_filter :load_annotatable

  def create
    @annotation.annotatable = @annotatable
    @annotation.creator_id = current_user.id
    unless @annotation.save
      set_flash_message(:alert, :could_not_annotate, errors: @annotation.errors.full_messages.join(', '))
    end
    redirect_to_annotatable
  end

  def destroy
    unless @annotation.destroy
      set_flash_message(:alert, :could_not_destroy, errors: @annotation.errors.full_messages.join(', '))
    end
    redirect_to_annotatable
  end

  protected

    def load_annotatable
      @annotatable = type.constantize.find(params[:user_id] || params[:order_id] || params[:cancelled_order_id])
    end

    def admin_path(annotatable)
      t = type.underscore
      t = 'order' if t == 'cancelled_order'
      send("admin_#{t}_path", annotatable.id)
    end

    def type
      request.path.split('/')[2].classify
    end

    def redirect_to_annotatable
      redirect_to(admin_path(@annotatable))
    end
end

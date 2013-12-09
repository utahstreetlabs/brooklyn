module Controllers
  module TagScoped
    extend ActiveSupport::Concern

    module ClassMethods
      def set_tag(options = {})
        before_filter(options) do
          @tag = Tag.find(params[:tag_id] || params[:id])
        end
      end
    end
  end
end

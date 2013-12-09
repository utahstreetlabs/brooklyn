module Controllers
  # Provides common behaviors for controllers that are scoped to a listing comment.
  module CommentScoped
    def self.included(base)
      base.extend(ClassMethods)
    end

  protected
    module ClassMethods
      def set_comment(options = {})
        before_filter(options) do
          @comment = @listing.find_comment(params[:comment_id])
          render_jsend(error: 'Comment not found', code: 404) unless @comment
        end
      end
    end
  end
end

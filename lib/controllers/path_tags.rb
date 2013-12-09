module Controllers
  module PathTags
    extend ActiveSupport::Concern

    included do
      class_eval <<-EOT
        helper_method :browse_for_sale_path_tags_path
      EOT
    end

    module ClassMethods
      def redirect_legacy_tags_to_path_tags(options={})
        before_filter options do
          if params[:tags]
            params[:path_tags] = tag_ids_to_path_tags(params.delete(:tags))
            redirect_to browse_for_sale_path(params), status: 301
          end
        end
      end

      def set_category(options = {})
        before_filter(options) do
          @category = Category.find_by_slug(params[:category]) if params[:category].present?
          params[:path_tags] = "#{params[:category]}/#{params[:path_tags]}" if @category.nil?
        end
      end

      def parameterize_path_tags(options={})
        before_filter options do
          params[:tags] = request.query_parameters['tags'] = path_tags_to_params(params[:path_tags]) if params[:path_tags]
        end
      end
    end

    module InstanceMethods
      def path_tags_to_params(path_tags)
        path_tags.split("/").compact.uniq
      end

      def tag_ids_to_path_tags(tag_ids)
        Tag.where(id: tag_ids).map(&:slug).join('/')
      end

      def browse_for_sale_path_tags_path(category, params={})
        new_params = params.dup
        new_params.delete(:path_tags)
        tags = new_params.delete(:tags)
        new_params[:path_tags] = tags.join('/') if tags and tags.any?
        new_params.delete(:page) if new_params.delete(:reset_pagination)
        # some existing params confuse the url helper
        new_params.delete(:category)
        new_params.delete(:controller)
        new_params.delete(:action)
        case (action_name || :all).to_sym
        when :new_arrivals then new_arrivals_for_sale_path(category, new_params)
        else browse_for_sale_path(category, new_params)
        end
      end
    end
  end
end

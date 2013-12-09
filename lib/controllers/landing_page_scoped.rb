module Controllers
  module LandingPageScoped
    extend ActiveSupport::Concern

    included do
      skip_requiring_login_only
    end

    module InstanceMethods
      def render_landing_page(directory)
        begin
          @referer = request.referer
          @default_body_class = "#{directory}_show"
          track_usage(:visit_landing_page, directory: directory, slug: params[:template])
          render(template: "#{directory}/#{params[:template].gsub('-', '_')}", layout: @skip_layout ? nil : 'landing_page')
        rescue ActionView::MissingTemplate => e
          respond_not_found
        end
      end
    end
  end
end

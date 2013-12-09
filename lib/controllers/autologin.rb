module Controllers
  module Autologin
    extend ActiveSupport::Concern

    included do
      helper_method :autologin_permitted?
    end

    module ClassMethods
      def enable_autologin(options = {})
        before_filter :enable_autologin, options
      end

      def skip_enable_autologin(options = {})
        skip_filter :enable_autologin, options
      end
    end

    protected
    def disable_autologin
      @enable_autologin = false
    end

    def autologin_permitted?
      @enable_autologin
    end

    def enable_autologin
      return false unless feature_enabled?(:autologin)
      return false if params[:noal]
      unless logged_in?
        @enable_autologin = true
      end
    end
  end
end

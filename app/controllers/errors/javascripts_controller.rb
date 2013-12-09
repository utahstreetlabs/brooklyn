module Errors
  class JavascriptsController < ApplicationController
    skip_requiring_login_only

    def create
      render_jsend(:success)
    end
  end
end

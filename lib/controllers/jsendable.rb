module Controllers
  module Jsendable
    # respond with jsend, wrapping in html if necessary
    def respond_with_jsend(jsend)
      respond_to do |format|
        format.json { render_jsend jsend}
        format.html { render_jsend wrap_html(jsend) }
      end
    end

    private

    def wrap_html(json)
      json.merge(render: {as: :text, layout: 'json'})
    end
  end
end

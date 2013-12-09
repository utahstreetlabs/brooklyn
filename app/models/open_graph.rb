module OpenGraph
  extend ActiveSupport::Concern

  module ClassMethods
    # Given an action and a bag of properties, return a hash suitable for submission
    # to the open graph action creation API:
    #
    # https://developers.facebook.com/docs/opengraph/actions/
    #
    # This method will merge action into options and transform the following properties:
    #
    # :to - given a user id, will transform into a facebook id and added to the :tags parameter
    # :fb_ref - will be used, along with :fb_ref_data, to create a facebook :ref parameter
    # :user_generated_images - each photo in this list will be added to the request as a
    #                          "user generated image"
    def open_graph_props(action, options = {})
      props = options.merge(action: action, namespace: options.delete(:ns) || :copious)
      to = props.delete(:to)
      if to.present?
        to_profile = User.find(to).person.for_network(:facebook)
        props[:tags] = to_profile.uid if to_profile && to_profile.uid.present?
      end
      params = {}
      fb_ref = props.delete(:fb_ref)
      params[:ref] = Network::Facebook::Ref.new(fb_ref, props.delete(:fb_ref_data)).to_ref if fb_ref
      ugi = props.delete(:user_generated_images)
      params.merge!(user_generated_images(ugi)) if ugi
      props[:params] = params
      props
    end

    def open_graph_object_props(action, object, link, options = {})
      open_graph_props(action, options.merge(object: object, link: link, fb_ref: "#{object}:#{action}"))
    end

    private

    def user_generated_images(images)
      if images
        images.each_with_index.reduce({}) do |m, (image, i)|
          m["image[#{i}][url]"] = image
          m["image[#{i}][user_generated]"] = true
          m
        end
      else
        {}
      end
    end
  end
end

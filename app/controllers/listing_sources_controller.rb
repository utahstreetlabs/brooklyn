class ListingSourcesController < ApplicationController
  respond_to :json
  set_flash_scope 'listing_sources'

  def create
    track_usage('scrape_external_listing click', username: current_user.slug, user: current_user,
                external_url: params[:url], listing_source: params[:source] || 'website')
    begin
      source = case (params[:source] || '').to_sym
      when :bookmarklet
        options = { url: params[:url], price: params[:price], title: params[:title], images: params[:images] }
        ListingSource.build_from_bookmarklet(options)
      else
        ListingSource.scrape(params[:url])
      end
      if source
        source.save!
        return render_jsend(success: {
          redirect: new_external_listing_path(source)
        })
      end
    rescue URI::InvalidURIError => e
      # user entered an invalid url
      e = e.message.gsub(": #{params[:url]}", '')
      logger.debug("Unable to scrape external listing source #{params[:url]}: #{e}")
    rescue Faraday::Error::ClientError => e
      # got an error response when trying to scrape the page
      logger.debug("Unable to scrape external listing source #{params[:url]}: #{e}")
    rescue ActiveRecord::RecordInvalid => e
      # we couldn't scrape enough information to create a valid source - generally this means there were no images
      # big enough (or for which we could find size information)
      logger.debug("Unable to scrape external listing source #{params[:url]}: #{e}")
    end
    render_jsend(fail: {
      message: localized_flash_message('create_error')
    })
  end
end

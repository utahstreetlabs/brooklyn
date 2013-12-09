module Listings::InstagramHelper
  # If we're connected to instagram already, just link to the importer.
  # Otherwise, open an authentication dialog in a new window and then
  # redirect to the importer once the authentication window has closed
  def link_to_import_photos_instagram(text, listing)
    profile = current_user ? current_user.person.for_network(:instagram) : nil
    profile && profile.connected?? link_to_upload_instagram(text, listing) : link_to_connect_instagram(text, listing)
  end

  def link_to_connect_instagram(text, listing)
    continue = bootstrap_button text, '#', toggle_modal: :instagram,
      class: 'upload-instagram instagram-import', style: 'display: none', id: 'continue', data: {role: 'modal-remote'}
    link = link_to text, nilhref, class: 'button connect-instagram large'
    content_tag :div, id: 'upload-instagram' do
      "#{continue}#{link}".html_safe
    end
  end

  def link_to_upload_instagram(text, listing)
    content_tag :div, id: 'upload-instagram' do
       link_to text, '#', data: {toggle: :modal, target: '#instagram-modal', role: 'modal-remote'},
       class: 'upload-instagram button large'
    end
  end

  def listing_instagram_photo_tag(photo, version, options = {})
    profile = logged_in?? current_user.person.for_network(:instagram) : nil
    image_tag(profile.photo_size_url(photo, version), {:alt => ''}.merge(options)) if profile
  end

  def instagram_photo_url(photo, version)
    photo.fetch('images', {}).fetch(version.to_s, {}).fetch('url', '')
  end

  def instagram_photos(photos, options={}, &b)
    content_tag(:ul, options, &b)
  end

  def instagram_import(listing, photo, options={})
    capture { render "/listings/instagram_import", options.merge(listing: listing, photo: photo, instagram_import_button_options: options) }
  end

  def instagram_import_button(listing, photo, options={})
    options.merge!({imported: :imported}) if listing.photos.map(&:source_uid).include?(photo['id'])
    if options[:imported]
      link_to 'Imported', '#', :class => 'button done disabled', rel: :nofollow, remote: true
    else
      link_to 'Import', listing_instagram_path(listing, photo['id'],
        url: instagram_photo_url(photo, :standard_resolution)),
        :class => 'button import remote-link', rel: :nofollow,
        remote: true, :'data-method' => :PUT, :'data-type' => :json
    end
  end
end

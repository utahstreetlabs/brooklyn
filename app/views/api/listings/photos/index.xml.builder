xml.instruct!

xml.photos do
  @listing.photos.each do |photo|
    xml.photo do
      xml.id photo.uuid
      xml.link "href" => absolute_url(photo.file.large.url, root_url: root_url)
      xml.source_uid photo.source_uid if photo.source_uid
    end
  end
end

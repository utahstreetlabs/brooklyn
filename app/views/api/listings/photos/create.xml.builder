xml.instruct!

xml.photo do
  xml.id @listing_photo.uuid
  xml.link "href" => absolute_url(@listing_photo.file.large.url, root_url: root_url)
  xml.source_uid @listing_photo.source_uid if @listing_photo.source_uid
end

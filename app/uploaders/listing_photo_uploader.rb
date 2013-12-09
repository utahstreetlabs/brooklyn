require 'carrierwave/processing/mime_types'

class ListingPhotoUploader < CarrierWave::Uploader::Base
  include CarrierWave::RMagick
  include CarrierWave::MimeTypes

  # Set the content type; carrierwave uses the extension if its available
  # but otherwise looks at image properties to guess the type.  Note that
  # combined with the extension whitelist below we'll only dive into image
  # properties if there is no extension present.
  process :set_content_type

  # 50x50
  version :xsmall, :if => :foreground_processing? do
    process :xsmall_image
  end

  # 75x75
  version :small do
    process :small_image
  end

  # 100x100
  version :px_100x100 do
    process :px_100x100_image
  end

  # 220x220
  version :px_220x220 do
    process :px_220x220_image
  end

  # 300x300
  version :medium, :if => :foreground_processing? do
    process :medium_image
  end

  # 460x460
  version :px_460x460, :if => :foreground_processing? do
    process :px_460x460_image
  end

  # Note for large, xlarge:
  # +resize_to_limit_and_pad+'s call to +manipulate!+ performs
  # the format conversion to update the tmp file's extension if necessary.
  # Nested calls to +manipulate!+ don't work, so we just do it there.
  version :large, :if => :foreground_processing? do
    process :resize_to_limit_and_pad => [460, nil]
  end

  version :xlarge, :if => :foreground_processing? do
    process :resize_to_limit_and_pad => [500, nil]
  end

  def xsmall_image
    manipulate!(format: format_from_content_type) do |img|
      img.resize_to_fill(50, 50)
    end
  end

  def small_image
    manipulate!(format: format_from_content_type) do |img|
      img.resize_to_fill(75, 75)
    end
  end

  def px_100x100_image
    manipulate!(format: format_from_content_type) do |img|
      img.resize_to_fill(100, 100)
    end
  end

  def px_220x220_image
    manipulate!(format: format_from_content_type) do |img|
      img.resize_to_fill(220, 220)
    end
  end

  def px_460x460_image
    manipulate!(format: format_from_content_type) do |img|
      img.resize_to_fill(460, 460)
    end
  end

  def medium_image
    manipulate!(format: format_from_content_type) do |img|
      img.resize_to_fill(300, 300)
    end
  end

  def format_from_content_type
    @format ||= begin
      f = @file.content_type.gsub(/(?:image|application)\//, "")
      # CarrierWave::IntegrityError is the same exception that is raised if a file
      # with an extension is not on the whitelist.
      raise CarrierWave::IntegrityError unless mime_type_white_list.include?(@file.content_type)
      f
    end
  end

  def foreground_processing?(file)
    not model.background_processing
  end

  # given a block, yields to the block with the image, destroying the image after the block returns
  def with_tmp_img(img, *args)
    r = yield(img, *args)
    destroy_image(img)
    r
  end

  def resize(img, width, height)
    with_tmp_img(img) do
      img.change_geometry(Magick::Geometry.new(width, height, 0, 0, Magick::GreaterGeometry)) do |new_width, new_height|
        [img.resize(new_width, new_height), new_width, new_height]
      end
    end
  end

  def create_padding_layer(width, height, background)
    with_tmp_img(::Magick::Image.new(width, height)) do |img|
      if background == :transparent
        img.matte_floodfill(1, 1)
      else
        img.color_floodfill(1, 1, ::Magick::Pixel.from_color(background))
      end
    end
  end

  def resize_to_limit_and_pad(width, height, background = :transparent, gravity= ::Magick::CenterGravity)
    ListingPhoto.benchmark "photo_upload: resizing #{width}x#{height} photo" do
      manipulate!(format: format_from_content_type) do |img|
        padded_image = with_tmp_img(*resize(img, width, height)) do |resized_image, new_width, new_height|
          with_tmp_img(create_padding_layer(width || new_width, height || new_height, background)) do |padding_layer|
            padding_layer.composite(resized_image, gravity, ::Magick::OverCompositeOp)
          end
        end

        if block_given?
          yield(padded_image)
        else
          padded_image
        end
      end
    end
  end

  def mime_type_white_list
    %w(image/jpeg image/gif image/png image/tiff image/fpx image/x-fpx application/x-troff-ms)
  end

  def extension_white_list
    # Allows a file with no extension to be uploaded; we'll attempt to get its
    # content type in order to process it.
    ['jpg', 'jpeg', 'gif', 'png', 'tif', 'tiff', 'fpx', 'ms', 'php', /^$/]
  end

  def store_dir
    path = "#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
    self.class.store_dir.present?? "#{self.class.store_dir}/#{path}" : path
  end

  def calculate_geometry
    img = ::Magick::Image.from_blob(@file.read).first
    [img.rows, img.columns]
  end
end

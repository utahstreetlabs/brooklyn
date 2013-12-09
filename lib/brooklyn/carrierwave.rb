# base implementation of the carrierwave file object that is free of their convoluted encapsulation and usable
# for testing and subclassing
module Brooklyn
  module CarrierWave
    class ImageFile
      attr_accessor :original_filename, :uid

      def initialize(filename)
        @original_filename = filename
      end

      def respond_to?(*args)
        super or file.respond_to?(*args)
      end

      def method_missing(*args, &block)
        file.send(*args, &block)
      end

      def file
        @file ||= read_file
      end

      def read_file
        raise "Unimplemented method 'read_file'"
      end
    end

    class LocalImageFile < ImageFile
      def initialize(path)
        @path = path
        super(File.basename(path))
      end

      def read_file
        s = StringIO.new
        IO.copy_stream(@path, s)
        s
      end
    end

    class RemoteImageFile < ImageFile
      def initialize(url, filename = nil)
        super(filename || url.split('/').last)
        @url = url
      end

      def read_file
        response = Typhoeus::Request.get(@url)
        raise "Error reading remote file '#{response.code}:#{response.status_message}'" unless response.success?
        s = StringIO.new(response.body)
      end
    end
  end
end

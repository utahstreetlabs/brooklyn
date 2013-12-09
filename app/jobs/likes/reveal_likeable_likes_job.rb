require 'ladon'
require 'pyramid/models/likeable/likes'

module Likes
  class RevealLikeableLikesJob < Ladon::Job
    @queue = :listings

    class << self
      def work(likeable_type, likeable_id)
        with_error_handling("Reveal likes for #{likeable_type} #{likeable_id}") do
          Pyramid::Likeable::Likes.reveal(likeable_id, likeable_type)
        end
      end
    end
  end
end

module Sync
  module Listings
    class ChannelAdvisorProvider
      include Sync::Listings::S3Fetchable

      def each(&block)
        tmp = Tempfile.new('channel', encoding: Encoding::UTF_8)
        self.class.latest_file { |l| tmp.write(l.encode(Encoding::UTF_8, Encoding::UTF_8)) }
        tmp.seek(0)

        # channel advisor doesn't use any quoting, i imagine assume there will be no \t's within fields (bold)
        # so we pick a char that shouldn't show up (the ascii bell) and pray.  awesome.
        csv = CSV.new(tmp, headers: :first_row, quote_char: "\a", col_sep: "\t")
        csv.each do |row|
          block.call(row)
        end
        tmp.close(true)
      end
    end
  end
end

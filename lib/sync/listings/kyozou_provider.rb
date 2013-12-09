module Sync
  module Listings
    class KyozouProvider
      include S3Fetchable

      def each(&block)
        # three problems to overcome here:
        #
        # 1) the actual csv file uses """ to quote multiline fields, but the CSV parser only understands single
        #    characters as quoting options
        # 2) even better! the UTF-8 BOM gets parsed as part of the first column in the header
        #    row.  so we seek past it.  awful.  just awful.
        # 3) Fog doesn't give us an opportunity to specify character encoding so we do some forcing to
        #    get it to behave right
        tmp = Tempfile.new('kyozou', encoding: Encoding::UTF_8)
        self.class.latest_file { |l| tmp.write(l.encode(Encoding::UTF_8, Encoding::UTF_8).gsub(/"{3}/, '"')) }
        tmp.seek(3)

        csv = CSV.new(tmp, headers: :first_row)
        csv.each do |row|
          block.call(row)
        end
        tmp.close(true)
      end
    end
  end
end

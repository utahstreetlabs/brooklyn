module Sync
  module Listings
    module S3Fetchable
      extend ActiveSupport::Concern

      included do
        instance_eval <<-EOT
          def bucket=(value)
            @bucket = value
          end

          def bucket
            @bucket
          end

          def pattern=(value)
            @pattern = value
          end

          def pattern
            @pattern
          end
        EOT
      end

      module ClassMethods
        def latest_file(&block)
          s3_client.directories.get(@bucket).files.get(latest_filename, &block)
        end

        def latest_filename
          bucket = s3_client.get_bucket(@bucket)
          re = Regexp.new(@pattern)
          # need the whole filename, but sort on the numerical portion
          file = bucket.body['Contents'].map {|f| re.match(f['Key']) }.compact.sort_by { |m| m[1].to_i }.last[0]
        end

        def s3_client
          @s3_client ||= Fog::Storage.new(s3_config)
        end

        def s3_config
          Brooklyn::Application.config.aws.marshal_dump.each_with_object({provider: 'AWS'}) do |(key,value),config|
            key = "aws_#{key}".to_sym if key.to_s =~ /key/
            config[key] = value
          end
        end
      end
    end
  end
end

require 'mogli'

module Brooklyn
  class GraphApi
    class << self
      attr_accessor :driver
      delegate :create_test_user, to: :driver
      delegate :get_test_user, to: :driver
      delegate :destroy_test_user, to: :driver
    end
  end

  class LiveGraphApiDriver
    MAX_FACEBOOK_RETRIES = 2

    def app_client
      Mogli::AppClient.new(Network::Facebook.access_token, Network::Facebook.app_id)
    end

    def get_test_user(options = {})
      return @test_user if @test_user && !options[:create]
      create_test_user(options)
    end

    def create_test_user(options = {})
      retries = 0
      query = options.reverse_merge(installed: true, permissions: Network::Facebook.scope)
      begin
        @test_user = Mogli::TestUser.create(query, app_client)
        Rails.logger.debug("Created Facebook test user #{@test_user.id}")
      rescue Mogli::Client::HTTPException
        unless retries >= MAX_FACEBOOK_RETRIES
          retries = retries + 1
          retry
        end
      end
      @test_user
    end

    def destroy_test_user(options = {})
      if @test_user
        retries = 0
        begin
          @test_user.destroy
          Rails.logger.debug("Destroyed Facebook test user #{@test_user.id}")
        rescue MultiJson::DecodeError => e
          unless retries >= MAX_FACEBOOK_RETRIES
            Rails.logger.warn "Facebook test user destroy response still is not json, msg => #{e.message}"
            retries = retries + 1
            retry
          end
        end
        @test_user = nil
      end
    end
  end
end

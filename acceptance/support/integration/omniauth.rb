module OmniAuthIntegrationHelpers
  def random_uid
    (SecureRandom.random_number * 1_000_000).to_i.to_s
  end

  def with_mocked_oauth
    OmniAuth.config.test_mode = true
    yield
    OmniAuth.config.test_mode = false
  end

  def given_twitter_profile(options = {})
    Rubicon::TwitterProfile.any_instance.stubs(:valid_credentials?).returns(true)
    # don't sync, cuz like, this profile doesn't exist on twitter
    Rubicon::TwitterProfile.any_instance.stubs(:sync)

    oauth = {
      uid: random_uid,
      info: {
        name: 'Kara Thrace',
        image: 'http://a2.twimg.com/profile_images/1095455373/avatar_normal.jpg',
        urls: {
          Twitter: 'http://twitter.com/starbuck',
        }
      },
      credentials: {
        token: 'cafebebe',
        secret: 'deadbeef',
      },
    }
    OmniAuth.config.add_mock(:twitter, oauth)
    oauth
  end

  shared_context 'mock twitter profile' do
    before do
      auth = given_twitter_profile
    end
  end

  def given_tumblr_profile(options = {})
    Rubicon::TumblrProfile.any_instance.stubs(:sync)
    OmniAuth.config.add_mock(:tumblr, {
      uid: random_uid,
      info: {
        name: 'Kara Thrace',
        image: 'http://tumblr.com/photos/starbuck.jpg',
        urls: {
          Tumblr: 'http://starbuck.tumblr.com/',
        }
      },
      credentials: {
        token: 'cafebebe',
        secret: 'deadbeef',
      },
    })
  end

  shared_context 'mock instagram profile' do
    before { given_instagram_profile }
  end

  def given_instagram_profile(options = {})
    Rubicon::InstagramProfile.any_instance.stubs(:sync)
    user = {
      uid: random_uid,
      info: {
        name: 'Kara Thrace',
        image: 'http://instagr.am/photos/starbuck.jpg',
      },
      credentials: {
        token: 'cafebebe'
      }}
    OmniAuth.config.add_mock(:instagram, user)
    OmniAuth.config.add_mock(:instagram_secure, user)
  end

  shared_context 'mock facebook profile' do
    before { given_facebook_profile }
  end

  def given_facebook_profile(options = {})
    Rubicon::FacebookProfile.any_instance.stubs(:valid_credentials?).returns(true)
    Rubicon::FacebookProfile.any_instance.stubs(:sync)

    params = {
      uid: random_uid,
      first_name: 'Kara',
      last_name: 'Thrace',
      email: 'starbuck@galactica.mil'
    }.merge(options)
    oauth = {
      uid: params[:uid],
      info: {
        name: "#{params[:first_name]} #{params[:last_name]}",
        first_name: params[:first_name],
        last_name: params[:last_name],
        email: params[:email],
        image: 'http://graph.facebook.com/100002623554963/picture?type=square',
        urls: {
          Facebook: "http://www.facebook.com/profile.php?id=100002623554963",
          Website: nil
        }},
      credentials: {
        token: 'cafebebe',
        secret: 'deadbeef',
      },
      scope: Network::Facebook.scope,
    }
    OmniAuth.config.add_mock(:facebook, oauth)
    oauth
  end
end

RSpec.configure do |config|
  config.include OmniAuthIntegrationHelpers
end

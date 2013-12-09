require './acceptance/spec_helper'

feature "Change profile photo" do
  background do
    login_as "starbuck@galactica.mil"
    visit settings_profile_path
  end

  scenario "upload new photo", js: true do
    attach_file "user_profile_photo", fixture('hamburgler.jpg')
    all("#field_photo img").first['src'].should =~ /hamburgler.jpg/
  end

  scenario "refresh photo from facebook", js: true do
    ProfilePhotoUploader.any_instance.stubs(:actual_url).returns("http://s3.amazonaws.com/utahstreetlabs-dev-utah/images/zach.jpg")

    click_button 'Refresh from Facebook'
    retry_expectations do
      all("#field_photo img").first['src'].should =~ /zach.jpg/
    end
  end
end

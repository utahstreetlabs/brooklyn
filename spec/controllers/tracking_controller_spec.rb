require 'spec_helper'

describe TrackingController do
  describe '#show' do
    it 'should set session variables for utm* parameters' do
      get_pixel utm_campaign: 'recruit_the_dead', utm_medium: 'seance', utm_content: 'dark_willow_001',
                utm_source: 'the mind', utm_term: 'shoes for ghosts',
                fb_ref: 'ghostclix'
      session[:mp_last_touch].should ==({utm_campaign: 'recruit_the_dead', utm_medium: 'seance',
                                         utm_content: 'dark_willow_001', utm_source: 'the mind',
                                         utm_term: 'shoes for ghosts', fb_ref: 'ghostclix'})
      session[:mp_first_touch].should ==({initial_utm_campaign: 'recruit_the_dead', initial_utm_medium: 'seance',
                                          initial_utm_content: 'dark_willow_001', initial_utm_source: 'the mind',
                                          initial_utm_term: 'shoes for ghosts'})
      response.should be_success
    end

    it 'should send an event to mixpanel if event is provided' do
      subject.expects(:track_usage).with('raised_dead')
      get_pixel event: 'raised_dead'
      response.should be_success
    end

    def get_pixel(*args)
      get :show, *args
    end
  end
end

require 'spec_helper'

describe Brooklyn::Mixpanel do
  subject { Brooklyn::Mixpanel }
  let(:distinct_id) { '9f8f8cac-2aa8-4ad0-9046-2c3be5af3f93c' }

  describe '#merge_global_properties' do
    let(:mp_cookies) do
      [["mp_fb3cff8696c1fb73791321119381fb17_mixpanel", "{\"$initial_referrer\": \"http://copious.com/\",\"$initial_referring_domain\": \"copious.com\",\"distinct_id\": \"9f8f8cac-2aa8-4ad0-9046-2c3be5af3f94a\",\"utm_source\": \"notifications\",\"utm_medium\": \"email\",\"utm_campaign\": \"userfollow\",\"mp_name_tag\": \"travis-vachon\"}"], ["mp_f1c0511258e178fc56c58fa3836d0afd_mixpanel", "{\"$initial_referrer\": \"http://copious.com/admin/users/62177\",\"$initial_referring_domain\": \"copious.com\",\"distinct_id\": \"#{distinct_id}\",\"mp_name_tag\": \"travis-vachon\"}"], ["mp_c1c03b5e26cec56272f26794d85651b9_mixpanel", "{\"$initial_referrer\": \"http://copious.com/\",\"$initial_referring_domain\": \"copious.com\",\"distinct_id\": \"9862749655\",\"mp_name_tag\": \"travis\"}"]]
    end

    it 'should find and merge the appropriate mp cookie data' do
      subject.merge_global_properties({distinct_id: distinct_id, mp_cookies: mp_cookies}).
        should == {distinct_id: distinct_id, :'$initial_referrer' => 'http://copious.com/admin/users/62177', :'$initial_referring_domain' => 'copious.com', mp_name_tag: 'travis-vachon'}
    end
  end

  describe '#merge_referrer_properties' do
    let(:referrer) { 'http://facebook.com/allurbase/r/belongtous' }

    it 'should remove the referrer value and parse it into $referrer and $referring_domain' do
      subject.merge_referrer_properties({referrer: referrer}).should ==(
        {:'$referrer' => referrer, :'$referring_domain' => 'facebook.com'})
    end

    it 'should return the given value unaltered if no referrer exists' do
      subject.merge_referrer_properties({a: :b}).should ==({a: :b})
    end
  end

  describe '#merge_user_agent_properties' do
    it 'should remove the user_agent value and parse it into $os and $browser' do
      subject.merge_user_agent_properties({user_agent: 'Opera/7.50 (Windows XP; U)'}).should ==(
        {:'$os' => 'Windows XP', :'$browser' => 'Opera'})
    end

    it 'should return the given value unaltered if no user_agent exists' do
      subject.merge_user_agent_properties({a: :b}).should ==({a: :b})
    end
  end

  describe '#merge_utm_properties' do
    it 'merge properties from utm_query_params' do
      query_params = {utm_campaign: 'hotdogs', utm_source: 'mindvertising', utm_medium: 'seance', utm_term: 'giger'}
      subject.merge_utm_properties({utm_query_params: query_params}).should == query_params
    end

    it 'should return the given value unaltered if no utm information exists' do
      subject.merge_utm_properties({a: :b}).should ==({a: :b})
    end
  end

  describe '#merge_fb_ref_properties' do
    let(:fb_ref) { Network::Facebook::Ref.new('foo,bar', {bar: :baz}).to_ref }

    it 'should remove the fb_ref parameter and add fb_type and fb-prefixed data properties' do
      subject.merge_fb_ref_properties({fb_ref: fb_ref}).should ==(
        {fb_types: ['foo', 'bar'], :'fb_bar' => 'baz'})
    end
  end

  describe '#post' do
    let(:success_response) { stub('success response', code: 200, body: '1') }
    it 'should post to the track url' do
      params = {hams: :clams}
      Typhoeus::Request.expects(:post).with('http://api.mixpanel.com/track', request(params)).returns(success_response)
      subject.post(:track, params)
    end

    it 'should post to the engage url' do
      params = {hams: :clams}
      Typhoeus::Request.expects(:post).with('http://api.mixpanel.com/engage', request(params)).returns(success_response)
      subject.post(:engage, params)
    end

    def request(data)
      {params: {data: ActiveSupport::Base64.encode64s(JSON.generate(data))}}
    end
  end

  describe '#track' do
    it 'should set distinct_id to visitor_id if passed' do
      subject.expects(:post).with(:track, tracking_props(:made_bacon, distinct_id: '2'))
      subject.track(:made_bacon, {visitor_id: '2'})
    end

    it 'should prefer distinct_id to visitor_id if both are passed' do
      subject.expects(:post).with(:track, tracking_props(:made_bacon, distinct_id: '1'))
      subject.track(:made_bacon, {distinct_id: '1', visitor_id: '2'})
    end

    def tracking_props(event, properties)
      {event: event, properties: properties.merge(token: subject.token)}
    end
  end

  describe '#set' do
    it 'should post to engage' do
      properties = {height: '54cm'}
      subject.expects(:post).with(:engage, set_props('1', properties))
      subject.set('1', properties)
    end

    def set_props(id, properties)
      engage_props(id, {:'$set' => properties})
    end
  end

  def engage_props(id, properties)
    properties.merge(:'$distinct_id' => id, :'$token' => subject.token)
  end

  describe '#referring_domain' do
    it 'parses out the domain of a valid URI' do
      subject.send(:referring_domain, 'http://www.copious.com/foo').should ==
        'www.copious.com'
    end

    it "returns nil if it can't parse the uri" do
      bad_uri = 'http://isearch.avg.com/search?cid={D043B7B4-23E4-4D04-AE84-28F32F71101D}&mid=af7c0be473f84159ba756009799e025d-3b3ea85badcace67c823a19345230ac77f762f0f&lang=en&ds=or011&pr=sa&d=2012-06-06 23:36:54&v=11.1.0.7&sap=dsp&q=copious'
      subject.send(:referring_domain, bad_uri).should == nil
    end
  end
end

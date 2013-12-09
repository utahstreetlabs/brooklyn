require 'spec_helper'

describe 'View Facebook canvas page' do
  let(:url) { '/facebook/canvas' }

  shared_examples 'FB canvas page' do
    it 'succeeds with GET' do
      get url
      expect(response).to be_success
      expect(response.body).to match(/#{root_url(secure: true)}/)
    end

    it 'succeeds with POST' do
      post url
      expect(response).to be_success
      expect(response.body).to match(/#{root_url(secure: true)}/)
    end

    it 'preserves src param' do
      get "#{url}?src=pa"
      expect(response).to be_success
      response.body =~ /redirect_uri=(.+)&scope/
      expect($1).to match(/src=pa/)
    end
  end

  context 'when not logged in' do
    it_behaves_like 'FB canvas page'
  end

  context 'when logged in' do
    include_context 'an authenticated session'
    it_behaves_like 'FB canvas page'
  end
end

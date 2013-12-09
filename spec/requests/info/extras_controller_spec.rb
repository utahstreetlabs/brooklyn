require 'spec_helper'

describe 'Extras' do
  let(:url) { "/info/extras" }

  it_behaves_like 'an anonymous request' do
    before do
      xhr :get, url
    end
  end

  context "when logged in" do
    include_context 'an authenticated session'

    it 'succeeds' do
      xhr :get, url
      expect(response).to render_template(:show)
    end
  end
end

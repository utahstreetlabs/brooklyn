require 'spec_helper'

describe 'LIH graphic view' do
  let!(:listing) { FactoryGirl.create(:active_listing) }

  it 'returns the first page of featured listings as HTML' do
    get '/', view: 'graphic'
    expect(response).to be_success
    expect(response.body).to_not include(listing.title)
  end
end

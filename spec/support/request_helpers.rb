module RequestHelpers
  shared_examples 'an anonymous request' do |options = {}|
    it 'fails' do
      if options[:xhr]
        expect(response).to be_jsend_unauthorized
      else
        expect(response.status).to eq(401)
      end
    end
  end

  shared_examples 'a non-admin request' do |options = {}|
    include_context 'an authenticated session'

    it 'fails' do
      if options[:xhr]
        expect(response).to be_jsend_unauthorized
      else
        expect(response.status).to eq(401)
      end
    end
  end

  shared_context 'an authenticated session' do |user_attrs = {}|
    let(:viewer) { FactoryGirl.create(:registered_user, user_attrs) }
    before do
      xhr :post, '/login', login: {email: viewer.email, password: 'test'}
    end
  end
end

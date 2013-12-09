require 'spec_helper'

describe Settings::Seller::IdentityController do
  describe "#update" do
    it_behaves_like "secured against anonymous users" do
      before { do_update }
    end

    context "for a logged-in user" do
      include_context "user is logged in"

      it_behaves_like 'with a merchant account' do
        before { do_update }
      end

      context "without a merchant account" do
        include_context 'user does not have a merchant account'

        context "and the input is valid" do
          before { Balanced::PersonMerchantIdentity.any_instance.stubs(:valid?).returns(true) }

          context "on the first attempt" do
            let(:attempt) { '1' }

            context "and the merchant is created" do
              before { user.stubs(:create_merchant!) }

              it "succeeds" do
                do_update(attempt: attempt)
                response.should redirect_to(settings_seller_accounts_path)
              end
            end

            context "and more information is required" do
              before { user.stubs(:create_merchant!).raises(Balanced::MoreInformationRequired.new(body: {})) }

              it 'redisplays the identity page with the first alert' do
                do_update(attempt: attempt)
                response.should render_template(:show)
                flash[:alert].should have_flash_message('settings.seller.identity.attempt2')
              end
            end
          end

          context "on the second attempt" do
            let(:attempt) { '2' }

            context "and the merchant is created" do
              before { user.stubs(:create_merchant!) }

              it "succeeds" do
                do_update(attempt: attempt)
                response.should redirect_to(settings_seller_accounts_path)
              end
            end

            context "and more information is required" do
              before { user.stubs(:create_merchant!).raises(Balanced::MoreInformationRequired.new(body: {})) }

              it 'redisplays the identity page with the second alert' do
                do_update(attempt: attempt)
                response.should render_template(:show)
                flash[:alert].should have_flash_message('settings.seller.identity.attempt3',
                  help_link: controller.view_context.mail_to(Brooklyn::Application.config.email.to.help))
              end
            end
          end

          context "on the third attempt" do
            let(:attempt) { '3' }

            context "and the merchant is created" do
              before { user.stubs(:create_merchant!) }

              it "succeeds" do
                do_update(attempt: attempt)
                response.should redirect_to(settings_seller_accounts_path)
              end
            end

            context "and more information is required" do
              before { user.stubs(:create_merchant!).raises(Balanced::MoreInformationRequired.new(body: {})) }

              it 'displays the failure page' do
                do_update(attempt: attempt)
                response.should render_template(:failure)
              end
            end
          end
        end

        context "and the input is not valid" do
          before { Balanced::PersonMerchantIdentity.any_instance.stubs(:valid?).returns(false) }

          it 'redisplays the identity page without an alert' do
            do_update
            response.should render_template(:show)
            flash[:alert].should be_nil
          end
        end
      end
    end

    def do_update(params = {})
      identity = {name: 'Ix Jonez', street_address: '472 Third St', postal_code: '94107',
                  phone_number: '415-555-1212', :'born_on(1i)' => '1974', :'born_on(2i)' => '02',
                  :'born_on(3i)' => '05', tax_id: '', attempt: '1'}.merge(params)
      put :update, identity: identity
    end
  end
end

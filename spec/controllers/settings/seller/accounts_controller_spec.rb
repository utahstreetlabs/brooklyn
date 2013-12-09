require 'spec_helper'

describe Settings::Seller::AccountsController do
  describe "#index" do
    it_behaves_like "secured against anonymous users" do
      before { do_index }
    end

    context "for a logged-in user" do
      include_context "user is logged in"

      it_behaves_like 'without a merchant account' do
        before { do_index }
      end

      context "with a merchant account" do
        include_context 'user has a merchant account'

        context "without deposit accounts" do
          include_context 'user does not have deposit accounts'

          it "redirects to new page" do
            do_index
            response.should redirect_to(new_settings_seller_account_path)
          end
        end

        context "with deposit accounts" do
          include_context 'user has deposit accounts'
          include_context 'user has proceeds awaiting settlement'

          it "shows index page" do
            do_index
            response.should render_template(:index)
          end
        end
      end
    end

    def do_index
      get :index
    end
  end

  describe "#new" do
    it_behaves_like "secured against anonymous users" do
      before { do_new }
    end

    context "for a logged-in user" do
      include_context "user is logged in"

      it_behaves_like 'without a merchant account' do
        before { do_new }
      end

      context "with a merchant account" do
        include_context 'user has a merchant account'
        include_context 'user has deposit accounts'
        include_context 'user has proceeds awaiting settlement'

        it "shows new page" do
          do_new
          response.should render_template(:new)
        end
      end
    end

    def do_new
      get :new
    end
  end

  describe "#create" do
    it_behaves_like "secured against anonymous users" do
      before { do_create }
    end

    context "for a logged-in user" do
      include_context "user is logged in"

      it_behaves_like 'without a merchant account' do
        before { do_create }
      end

      context "with a merchant account" do
        include_context 'user has a merchant account'
        include_context 'user has proceeds awaiting settlement'

        context "when creating a bank account" do
          context "and the input is valid" do
            before { BankAccount.any_instance.stubs(:save).returns(true) }

            context "and this is the first deposit account" do
              include_context 'user does not have deposit accounts'

              it "succeeds" do
                do_create
                response.should redirect_to(settings_seller_accounts_path)
                flash[:notice].should have_flash_message('settings.seller.accounts.payout_account_created')
              end
            end

            context "and this is not the first deposit account" do
              include_context 'user has deposit accounts'

              it "succeeds" do
                do_create
                response.should redirect_to(settings_seller_accounts_path)
                flash[:notice].should have_flash_message('settings.seller.accounts.deposit_account_created')
              end
            end
          end

          context "and the input is not valid" do
            before { BankAccount.any_instance.stubs(:save).returns(false) }

            context "and this is the first deposit account" do
              include_context 'user does not have deposit accounts'

              it "redisplays the new page" do
                do_create
                response.should render_template(:new)
              end
            end

            context "and this is not the first deposit account" do
              include_context 'user has deposit accounts'

              it "succeeds" do
                do_create
                response.should render_template(:index)
              end
            end
          end

          context "and the bank cannot be identified" do
            before { BankAccount.any_instance.stubs(:save).raises(DepositAccount::UnidentifiedBank) }

            context "and this is the first deposit account" do
              include_context 'user does not have deposit accounts'

              it "redisplays the new page with an alert" do
                do_create
                response.should render_template(:new)
                flash[:alert].should be
              end
            end

            context "and this is not the first deposit account" do
              include_context 'user has deposit accounts'

              it "displays the index page with an alert" do
                do_create
                response.should render_template(:index)
                flash[:alert].should be
              end
            end
          end
        end
      end
    end

    def do_create
      post :create, account_type: DepositAccount::BANK,
           account: {name: 'Checking', number: '012-34-5678', routing_number: '021000021', default: '1'}
    end
  end
end

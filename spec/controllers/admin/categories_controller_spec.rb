require 'spec_helper'

describe Admin::CategoriesController do
  describe "#index" do
    it_behaves_like "secured against anonymous users" do
      before { do_index }
    end

    it_behaves_like "secured against rfbs" do
      before { do_index }
    end

    describe "as an admin user" do
      include_context 'for an admin user'

      it "succeeds" do
        categories = stub('categories')
        Category.expects(:datagrid).with(is_a(Hash)).returns(categories)
        do_index
        response.should render_template(:index)
        assigns[:categories].should == categories
      end
    end

    def do_index
      get :index
    end
  end

  describe "#show" do
    include_context 'category scoped'

    it_behaves_like "secured against anonymous users" do
      before { do_show }
    end

    it_behaves_like "secured against rfbs" do
      before { do_show }
    end

    describe "as an admin user" do
      include_context 'for an admin user'
      include_context 'expects category'

      it "succeeds" do
        dwv = stub('dwv')
        category.expects(:dimensions_with_values).returns(dwv)
        features = stub('features')
        category.expects(:features_with_listings).returns(features)
        do_show
        response.should render_template(:show)
        assigns[:dimensions].should == dwv
        assigns[:features].should == features
      end
    end

    def do_show
      get :show, id: category.slug
    end
  end
end

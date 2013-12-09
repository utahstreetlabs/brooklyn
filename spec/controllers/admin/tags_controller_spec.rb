require 'spec_helper'

describe Admin::TagsController do
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
        tags = [FactoryGirl.create(:tag)]
        do_index
        response.should render_template(:index)
        assigns[:tags].should == tags
      end
    end

    def do_index
      get :index
    end
  end

  describe "#show" do
    include_context 'tag scoped'

    it_behaves_like "secured against anonymous users" do
      before { do_show }
    end

    it_behaves_like "secured against rfbs" do
      before { do_show }
    end

    describe "as an admin user" do
      include_context 'for an admin user'
      include_context 'expects tag'

      it "succeeds" do
        features = stub('features')
        tag.stubs(:features_with_listings).returns(features)
        tag.stubs(:subtags).returns([])
        do_show
        response.should render_template(:show)
        assigns[:features].should == features
      end
    end

    def do_show
      get :show, id: tag.id
    end
  end

  describe "#new" do
    it_behaves_like "secured against anonymous users" do
      before { do_new }
    end

    it_behaves_like "secured against rfbs" do
      before { do_new }
    end

    describe "as an admin user" do
      include_context 'for an admin user'

      it "succeeds" do
        do_new
        response.should render_template(:new)
        assigns[:tag].should be_a(Tag)
      end
    end

    def do_new
      get :new
    end
  end

  describe "#create" do
    let(:tag_params) { {name: 'foo', slug: 'foo'} }

    it_behaves_like "secured against anonymous users" do
      before { do_create }
    end

    it_behaves_like "secured against rfbs" do
      before { do_create }
    end

    describe "as an admin user" do
      include_context 'for an admin user'

      it "saves the tag" do
        Tag.any_instance.expects(:save).returns(true)
        Tag.any_instance.expects(:id).returns(123)
        do_create
        assigns[:tag].should be_a(Tag)
        response.should redirect_to(admin_tag_path(123))
        flash[:notice].should have_flash_message('admin.tags.created', name: tag_params[:name])
      end

      it "fails to save the tag" do
        Tag.any_instance.expects(:save).returns(false)
        do_create
        assigns[:tag].should be_a(Tag)
        response.should render_template(:new)
      end
    end

    def do_create
      post :create, tag: tag_params
    end
  end

  describe "#edit" do
    include_context 'tag scoped'

    it_behaves_like "secured against anonymous users" do
      before { do_edit }
    end

    it_behaves_like "secured against rfbs" do
      before { do_edit }
    end

    describe "as an admin user" do
      include_context 'for an admin user'
      include_context 'expects tag'

      it "succeeds" do
        do_edit
        response.should render_template(:edit)
      end
    end

    def do_edit
      get :edit, id: tag.id
    end
  end

  describe "#update" do
    include_context 'tag scoped'

    let(:tag_params) { {name: 'foo'} }

    it_behaves_like "secured against anonymous users" do
      before { do_update }
    end

    it_behaves_like "secured against rfbs" do
      before { do_update }
    end

    describe "as an admin user" do
      include_context 'for an admin user'
      include_context 'expects tag'

      before do
        tag.expects(:attributes=).with(tag_params.stringify_keys)
        tag.expects(:slug=).with(nil)
      end

      it "saves the tag" do
        tag.expects(:save).returns(true)
        do_update
        assigns[:tag].should == tag
        response.should redirect_to(admin_tag_path(tag.id))
        flash[:notice].should have_flash_message('admin.tags.updated', name: tag.name)
      end

      it "fails to save the tag" do
        tag.expects(:save).returns(false)
        do_update
        assigns[:tag].should == tag
        response.should render_template(:edit)
      end
    end

    def do_update
      put :update, id: tag.id, tag: tag_params
    end
  end

  describe "#merge" do
    include_context 'tag scoped'

    it_behaves_like "secured against anonymous users" do
      before { do_merge }
    end

    it_behaves_like "secured against rfbs" do
      before { do_merge }
    end

    describe "as an admin user" do
      include_context 'for an admin user'
      include_context 'expects tag'

      it "merges tags when some are selected" do
        merge_ids = [42, 23, 96, 76]
        tag.expects(:merge).with(merge_ids.map(&:to_s))
        do_merge(merge_ids)
        response.should redirect_to(admin_tags_path)
        flash[:notice].should have_flash_message('admin.tags.merged', name: tag.name)
      end

      it "does nothing when no tags are selected" do
        tag.expects(:merge).never
        do_merge
        response.should redirect_to(admin_tags_path)
        flash[:alert].should have_flash_message('admin.tags.merge_none_selected')
      end
    end

    def do_merge(merge_ids = [])
      params = {id: tag.id}
      params[:merge_id] = merge_ids if merge_ids.any?
      post :merge, params
    end
  end

  describe "#promote" do
    include_context 'tag scoped'

    it_behaves_like "secured against anonymous users" do
      before { do_promote }
    end

    it_behaves_like "secured against rfbs" do
      before { do_promote }
    end

    describe "as an admin user" do
      include_context 'for an admin user'
      include_context 'expects tag'

      it "succeeds" do
        tag.expects(:promote)
        do_promote
        response.should redirect_to(admin_tags_path)
        flash[:notice].should have_flash_message('admin.tags.promoted', name: tag.name)
      end
    end

    def do_promote
      post :promote, id: tag.id
    end
  end

  describe "#destroy" do
    include_context 'tag scoped'

    it_behaves_like "secured against anonymous users" do
      before { do_destroy }
    end

    it_behaves_like "secured against rfbs" do
      before { do_destroy }
    end

    describe "as an admin user" do
      include_context 'for an admin user'
      include_context 'expects tag'

      it "succeeds" do
        tag.expects(:destroy)
        tag.expects(:primary?).returns(true)
        do_destroy
        response.should redirect_to(admin_tags_path)
        flash[:notice].should have_flash_message('admin.tags.removed', name: tag.name)
      end
    end

    def do_destroy
      delete :destroy, id: tag.id
    end
  end

  describe "#destroy_all" do
    it_behaves_like "secured against anonymous users" do
      before { do_destroy_all }
    end

    it_behaves_like "secured against rfbs" do
      before { do_destroy_all }
    end

    describe "as an admin user" do
      include_context 'for an admin user'

      let(:tag1) { stub_tag('planet caravan') }
      let(:tag2) { stub_tag('iron man') }

      it "destroys tags when some are selected" do
        ids = [tag1.id, tag2.id]
        Tag.expects(:destroy_all).with(id: ids.map(&:to_s))
        do_destroy_all(ids)
        response.should redirect_to(admin_tags_path)
        flash[:notice].should have_flash_message('admin.tags.destroyed_all')
      end

      it "does nothing when no tags are selected" do
        Tag.expects(:destroy_all).never
        do_destroy_all
        response.should redirect_to(admin_tags_path)
        flash[:alert].should have_flash_message('admin.tags.destroy_all_none_selected')
      end
    end

    def do_destroy_all(ids = [])
      params = {}
      params[:id] = ids if ids.any?
      delete :destroy_all, params
    end
  end
end

require 'spec_helper'

describe TagsController do
  describe '#like' do
    let(:tag) { stub_tag 'squeegees' }

    it_behaves_like "xhr secured against anonymous users" do
      before { do_put }
    end

    context 'as a logged-in user' do
      include_context "for a logged-in user"

      before do
        Tag.expects(:find_by_slug!).with(tag.id.to_s).returns(tag)
      end

      it 'likes another user' do
        subject.current_user.expects(:like).with(tag)
        do_put
        response.should be_jsend_success
        response.jsend_data['button'].should be
      end
    end

    def do_put
      xhr :put, :like, tag_id: tag.id.to_s, format: :json
    end
  end

  describe '#unlike' do
    let(:tag) { stub_user 'toilet-brushes' }

    it_behaves_like "xhr secured against anonymous users" do
      before { do_delete }
    end

    context 'as a logged-in user' do
      include_context "for a logged-in user"

      before do
        Tag.expects(:find_by_slug!).with(tag.id.to_s).returns(tag)
      end

      it 'likes another user' do
        subject.current_user.expects(:unlike).with(tag)
        do_delete
        response.should be_jsend_success
        response.jsend_data['button'].should be
      end
    end

    def do_delete
      xhr :delete, :unlike, tag_id: tag.id.to_s, format: :json
    end
  end
end

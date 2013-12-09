require 'spec_helper'

describe 'layouts/_masthead.html' do
  let(:page) do
    rendered = render(partial: 'layouts/masthead')
    Capybara::Node::Simple.new(rendered)
  end
  before do
    view.stubs(:poll_new_stories?).returns(true)
    view.stubs(:poll_notifications?).returns(true)
    view.stubs(:unviewed_notification_count).returns(0)
  end

  context 'for a logged in user' do
    before { act_as_rfb }

    context 'when there is a notification count' do
      before { view.stubs(:unviewed_notification_count).returns(5) }
      it 'should show the count' do
        find(:css, '[data-role=notification-pill]').text.should == '5'
      end
    end

    context 'when notification count is 0' do
      it 'should show the count' do
        find(:css, '[data-role=notification-pill]').should_not be_visible
      end
    end
  end
end

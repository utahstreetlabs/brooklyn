require 'spec_helper'

describe Controllers::Mixpanel, type: :controller do
  class MixpanelEnabledController < ActionController::Base
    include Controllers::Mixpanel
  end

  controller(MixpanelEnabledController) do
  end

  USER_AGENTS = {
    '' => true,
    'googlebot/1.1' => true,
    'baidu-spider/2.0' => true,
    'NewRelicPinger/0.1' => true,
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_8) AppleWebKit/537.31 (KHTML, like Gecko) Chrome/26.0.1410.43 ' +
    'Safari/537.31' => false,
  }

  describe '#user_agent_is_a_bot?' do
    before { request.env['HTTP_USER_AGENT'] = user_agent }

    USER_AGENTS.each do |ua, bot|
      context "for user-agent '#{ua}'" do
        let(:user_agent) { ua }
        it "returns #{bot}" do
          expect(subject.send(:user_agent_is_a_bot?)).to eq(bot)
        end
      end
    end
  end
end

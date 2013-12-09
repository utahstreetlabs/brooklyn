require 'spec_helper'

describe TutorialBar do
  describe "#completed?" do
    it 'should be true if all steps are true' do
      TutorialBar.new([step(complete?: true)]).complete?.should be_true
      TutorialBar.new([step(complete?: true), step(complete?: true)]).complete?.should be_true
    end

    it 'should be false if any step is false' do
      TutorialBar.new([step(complete?: false)]).complete?.should be_false
      TutorialBar.new([step(complete?: true), step(complete?: false)]).complete?.should be_false
      TutorialBar.new([step(complete?: false), step(complete?: true)]).complete?.should be_false
      TutorialBar.new([step(complete?: false), step(complete?: false)]).complete?.should be_false
    end
  end

  describe TutorialBar::LikeStep do
    describe 'complete?' do
      it 'should return true if the user has liked anything' do
        TutorialBar::LikeStep.new(stub('lover?' => true)).complete?.should be_true
      end
      it 'should return false if the user has not liked anything' do
        TutorialBar::LikeStep.new(stub('lover?' => false)).complete?.should be_false
      end
    end
  end

  describe TutorialBar::InviteStep do
    let(:facebook_user) { stub_user('facebook user', 'inviter?' => inviter, person: stub_person('fb person', networks: [:facebook])) }
    let(:twitter_user) { stub_user('twitter user', person: stub_person('twitter person', networks: [:twitter])) }
    describe 'complete?' do
      context 'when the user has invited someone' do
        let(:inviter) { true }
        it 'should return true' do
          TutorialBar::InviteStep.new(facebook_user).complete?.should be_true
        end
      end

      context 'when the user has not invited someone' do
        let(:inviter) { false }
        it 'should return true' do
          TutorialBar::InviteStep.new(facebook_user).complete?.should be_false
        end
      end

      it 'should always return true for twitter users' do
        TutorialBar::InviteStep.new(twitter_user).complete?.should be_true
      end
    end
  end

  def step(args)
    stub(args.merge('suggested=' => nil))
  end
end

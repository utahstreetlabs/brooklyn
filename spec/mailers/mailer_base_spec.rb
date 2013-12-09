require 'spec_helper'

describe MailerBase do
  class FooMailer < MailerBase
  end

  subject { FooMailer.send(:new) }

  describe '.google_analytics' do
    let(:source) { 'notifications' }
    let(:campaign) { 'welcome' }
    before { subject.google_analytics(source: source, campaign: campaign) }
    its(:link_params) { should include('utm_source' => source, 'utm_campaign' => campaign, 'utm_medium' => 'email') }
  end

  describe '.split_test_with' do
    let(:metric) { 'explosions' }

    context 'with visitor id' do
      let(:visitor_id) { 'deadbeef'}
      before { subject.split_test_with(visitor_id, metric) }
      its(:link_params) { should include('_track' => metric, '_identity' => visitor_id)}
    end

    context 'without visitor id' do
      let(:visitor_id) { nil }
      it 'does not blow up' do
        expect { subject.split_test_with(visitor_id, metric) }.to_not raise_error
      end
    end
  end

  describe '.setup_mail' do
    let(:action) { :welcome }

    it 'computes a subject' do
      params = {}
      subject_header = 'Chosen subject'
      subject.expects(:choose_subject).with(action, params).returns(subject_header)
      subject.expects(:mail).with(has_entries(subject: subject_header))
      subject.setup_mail(action, params: params)
    end

    it 'uses a custom subject' do
      subject_header = 'Custom subject'
      subject.expects(:choose_subject).never
      subject.expects(:mail).with(has_entries(subject: subject_header))
      subject.setup_mail(action, headers: {subject: subject_header})
    end
  end

  describe '.choose_subject' do
    let(:action) { :welcome }
    let(:params) { {} }

    context 'when split testing' do
      let(:metric) { 'explosions' }
      let(:number_of_alternatives) { 2 }
      let(:visitor_id) { 'deadbeef'}
      let(:scope) { [:mailers, subject.mailer_name, action, :subject] }
      let(:key) { 'hams' }
      let(:subject_header) { 'First alternative' }
      before { subject.split_test_with(visitor_id, metric) }
      it 'chooses an alternative' do
        subject.expects(:experiment_active?).returns(true)
        subject.expects(:ab_test).returns(key)
        I18n.expects(:t).with(key, has_entries(params.merge(scope: scope))).returns(subject_header)
        subject.choose_subject(action, params).should == subject_header
      end
    end

    context 'when not split testing' do
      let(:scope) { [:mailers, subject.mailer_name, action] }
      let(:key) { :subject }
      let(:subject_header) { 'Default subject' }
      it 'uses the default subject' do
        subject.subject_split_test.expects(:choose_alternative).never
        I18n.expects(:t).with(key, has_entries(params.merge(scope: scope))).returns(subject_header)
        subject.choose_subject(action, params).should == subject_header
      end
    end
  end
end

require 'spec_helper'

describe ActionView::Helpers::DateHelper do
  describe '#distance_of_time_in_words' do
    it 'returns the built-in string for less than 1 month' do
      distance_of_time_in_words(28.days.ago, Time.now).should eq('28 days')
    end

    it 'returns the custom string for 1 month' do
      # threshold is 29 days, 23 hrs, 59 mins, 30 secs
      # need to buffer against spring DST change, so give it an extra hour
      distance_of_time_in_words((30.days + 1.hour).ago, Time.now).should eq('more than a month')
    end

    it 'returns the custom string for multiple months' do
      # threshold is 59 days, 23 hrs, 59 mins, 30 secs
      distance_of_time_in_words(60.days.ago, Time.now).should eq('more than a month')
    end

    it 'returns the custom string for 1 year' do
      # threshold is 1 year ago
      distance_of_time_in_words(1.year.ago, Time.now).should eq('more than a month')
    end

    it 'returns the custom string for over 1 year' do
      # threshold is 1 yr, 3 months
      distance_of_time_in_words(15.months.ago, Time.now).should eq('more than a month')
    end

    it 'returns the custom string for almost 2 years' do
      # threshold is 1 yr, 9 months
      distance_of_time_in_words(21.months.ago, Time.now).should eq('more than a month')
    end

    it 'returns the custom string for 2 years' do
      # threshold is 2 years ago
      distance_of_time_in_words(2.years.ago, Time.now).should eq('more than a month')
    end

    it 'returns the custom string for over 2 years' do
      # threshold is 2 yr, 3 months
      distance_of_time_in_words(27.months.ago, Time.now).should eq('more than a month')
    end

    it 'returns the custom string for over 2 years' do
      # threshold is 12 yr, 9 months
      distance_of_time_in_words(33.months.ago, Time.now).should eq('more than a month')
    end
  end
end

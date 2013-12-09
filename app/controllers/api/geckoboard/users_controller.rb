class Api::Geckoboard::UsersController < Api::GeckoboardController
  STATES = ['guest', 'connected', 'registered']

  # data to compare current registered count to where we were 7 days ago
  def count
    data = [User.registered.count, User.registered_before(1.week.ago).count]
    data = { item: data.map { |c| { text: '', value: c } } }
    render json: data
  end

  # data for a red-amber-green chart
  def states
    counts = User.count_by_state
    data = { item: STATES.map { |state| { text: state, value: counts.fetch(state, 0) } } }
    render json: data
  end

  # data for a line chart over the last 14 days
  def registrations
    render json: { item: User.registrations_by_day(14).values }
  end
end

module VanityHelpers
  def stub_ab_test(experiment, outcome)
    Vanity.playground.experiment(experiment).expects(:choose).returns(stub('alternative', value: outcome))
  end
end

RSpec.configure do |config|
  config.include VanityHelpers
  config.before { Vanity.context = stub(vanity_identity: 1) }
end

FactoryBot.define do
  factory :trm_blue_shift do
    created_on { Faker::Date.backward(days: 1) }
    # metric needs to be set, with contexts
    # property needs to be set, with contexts
    # user needs to be set, with contexts
    manager_problem { false }
    market_problem { false }
    marketing_problem { false }
    capital_problem { false }
  end
end

FactoryBot.define do
  factory :blue_shift do
    created_on { Faker::Date.backward(days: 1) }
    # metric needs to be set, with contexts
    # property needs to be set, with contexts
    # user needs to be set, with contexts
    people_problem { false }
    product_problem { false }
    pricing_problem { false }
    need_help { false }
  end
end

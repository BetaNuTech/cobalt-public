FactoryBot.define do
  factory :metric do
    # property needs to be set, with contexts
    date { Faker::Date.backward(days: 3) }
    position { 2 }
    basis { 100 }
    physical_occupancy { 100 }
    trending_average_daily { 100 } 
    main_metrics_received { true }
  end
end

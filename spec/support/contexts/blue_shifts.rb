RSpec.shared_context "blue_shifts" do
  let(:blue_shift_valid_case_1) { 
    create(:blue_shift, property: default_property, metric: default_metric, user: admin_user, 
    people_problem: true, 
    people_problem_details: "The problem is...",
    people_problem_fix: "More cow bell",
    people_problem_fix_by: Faker::Date.forward(days: 14),
    people_problem_reason_specific_people: true,
    people_problem_specific_people: "John Doe",
    product_problem: false,
    pricing_problem: false,
    need_help: false ) 
  } 

  let(:blue_shift_valid_case_2) { 
    create(:blue_shift, property: default_property, metric: default_metric, user: admin_user, 
    people_problem: false, 
    no_people_problem_reason: "I just don't see a problem here",
    no_people_problem_checked: true,
    product_problem: true,
    product_problem_details: "The problem is...",
    product_problem_reason_maintenance_staff: true,
    product_problem_specific_people: "Joe Bob",
    product_problem_fix: "More cow bell",
    product_problem_fix_by: Faker::Date.forward(days: 14),
    pricing_problem: false,
    need_help: false )
  } 

  let(:blue_shift_valid_case_3) { 
    create(:blue_shift, property: default_property, metric: default_metric, user: admin_user, 
    people_problem: false, 
    no_people_problem_reason: "I just don't see a problem here",
    no_people_problem_checked: true,
    product_problem: false,
    pricing_problem: true,
    pricing_problem_fix: "More cow bell",
    pricing_problem_fix_by: Faker::Date.forward(days: 14),
    need_help: false )
  } 

  let(:blue_shift_valid_case_4) { 
    create(:blue_shift, property: default_property, metric: default_metric, user: admin_user, 
    people_problem: false, 
    no_people_problem_reason: "I just don't see a problem here",
    no_people_problem_checked: true,
    product_problem: false,
    pricing_problem: false,
    need_help: true,
    need_help_with: "The problem is...",
    need_help_marketing_problem: true )
  } 

  let(:blue_shift_valid_case_5) { 
    create(:blue_shift, property: default_property, metric: default_metric, user: admin_user, 
    people_problem: false, 
    no_people_problem_reason: "I just don't see a problem here",
    no_people_problem_checked: true,
    product_problem: false,
    pricing_problem: false,
    need_help: true,
    need_help_with: "The problem is...",
    need_help_capital_problem: true,
    need_help_capital_problem_explained: "Just not enough money." )
  } 

end

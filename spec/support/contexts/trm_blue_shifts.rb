RSpec.shared_context "trm_blue_shifts" do
  let(:trm_blue_shift_valid_case_1) { 
    create(:trm_blue_shift, property: default_property, metric: default_metric, user: admin_user, 
    manager_problem: true, 
    manager_problem_details: "The problem is...",
    manager_problem_fix: "More cow bell",
    manager_problem_fix_by: Faker::Date.forward(days: 14),
    market_problem: false,
    marketing_problem: false,
    capital_problem: false )
  } 

  let(:trm_blue_shift_valid_case_2) { 
    create(:trm_blue_shift, property: default_property, metric: default_metric, user: admin_user, 
    manager_problem: false, 
    market_problem: true,
    market_problem_details: "The problem is...",
    marketing_problem: false,
    capital_problem: false )
  } 

  let(:trm_blue_shift_valid_case_3) { 
    create(:trm_blue_shift, property: default_property, metric: default_metric, user: admin_user, 
    manager_problem: false, 
    market_problem: false,
    marketing_problem: true,
    marketing_problem_details: "The problem is...",
    marketing_problem_fix: "More cow bell",
    marketing_problem_fix_by: Faker::Date.forward(days: 14),
    capital_problem: false )
  } 

  let(:trm_blue_shift_valid_case_4) { 
    create(:trm_blue_shift, property: default_property, metric: default_metric, user: admin_user, 
    manager_problem: false, 
    market_problem: false,
    marketing_problem: false,
    capital_problem: true,
    capital_problem_details: "The problem is..." )
  } 


end

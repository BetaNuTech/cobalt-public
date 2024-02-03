class AddNeedHelpMarketingAndCapitalToBlueShifts < ActiveRecord::Migration
  def up
    add_column :blue_shifts, :need_help_marketing_problem, :boolean
    add_column :blue_shifts, :need_help_marketing_problem_marketing_reviewed, :boolean
    add_column :blue_shifts, :need_help_capital_problem, :boolean
    add_column :blue_shifts, :need_help_capital_problem_explained, :text
    add_column :blue_shifts, :need_help_capital_problem_asset_management_reviewed, :boolean
    add_column :blue_shifts, :need_help_capital_problem_maintenance_reviewed, :boolean
  end

  def down
    remove_column :blue_shifts, :need_help_marketing_problem
    remove_column :blue_shifts, :need_help_marketing_problem_marketing_reviewed
    remove_column :blue_shifts, :need_help_capital_problem
    remove_column :blue_shifts, :need_help_capital_problem_explained
    remove_column :blue_shifts, :need_help_capital_problem_asset_management_reviewed
    remove_column :blue_shifts, :need_help_capital_problem_maintenance_reviewed
  end
end

class AddSurveyDateToCompSurveyByBedDetails < ActiveRecord::Migration
  def change
    add_column :comp_survey_by_bed_details, :survey_date, :date, index: true
  end
end

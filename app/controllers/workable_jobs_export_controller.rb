class WorkableJobsExportController < ApplicationController

  include ActionView::Helpers::DateHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::NumberHelper

  def index
    authorize! :show_workable_jobs, WorkableJob.new()

    open_states = ["published", "closed"]
    open_jobs = WorkableJob.where(state: open_states).merge(Property.order("code ASC"))
    respond_to do |format|
      format.csv { send_data open_jobs.to_csv, filename: "jobs-#{Date.today}.csv" }
    end
  end

end

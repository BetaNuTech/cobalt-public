require 'active_record/fixtures'
 
namespace :db do
  task :seed_development => :environment do
    load_fixtures 'development_seeds'
    puts "Development data loaded."
  end
  
  task :development => ['environment', 'drop', 'create', 'migrate', 'seed', 'add_metrics'] do       
    load_fixtures 'development_seeds'

    # spawn a new process so rails env test may be used
    system("rake db:test:load")
  end
  
  task :add_metrics => :environment  do 
    spreadsheet_file_path =  "#{Rails.root}/db/daily_report.xlsx"
    Metrics::Commands::ImportExcelSpreadsheet.new(spreadsheet_file_path, 'http://localhost:3000').perform
    Metric.where("created_at > ?", 30.seconds.ago)
      .update_all(date: Time.now.to_date, created_at: DateTime.now)
  end

  task :add_historical_metrics => :environment do
    spreadsheet_file_path =  "#{Rails.root}/db/daily_report.xlsx"
    Metrics::Commands::ImportExcelSpreadsheet.new(spreadsheet_file_path, 'http://localhost:3000').perform
    oldest_metric = Metric.order("date ASC").first
    puts oldest_metric.date
    Metric.where("created_at > ?", 30.seconds.ago)
    .update_all(date: oldest_metric.date - 1.day)
  end  
  # task :add_historical_metrics => :environment do
  #   spreadsheet_file_path =  "#{Rails.root}/db/daily_report_historical.xls"
  #   Metrics::Commands::ImportExcelSpreadsheet.new(spreadsheet_file_path).perform    
  # end
  
  task :delete_duplicate_metrics => :environment do
    dates = Metric.select(:date).distinct.pluck(:date)
    dates.each do |date|
      Property.all.each {|p| m = Metric.where(date: date).where(property: p); m.last.destroy if m.length > 1; }
    end
  end
  
  private 
  def load_fixtures seed
   require File.join(Rails.root, 'db', seed + '.rb')
  end  
end

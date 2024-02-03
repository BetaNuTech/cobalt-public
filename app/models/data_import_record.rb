# == Schema Information
#
# Table name: data_import_records
#
#  id            :integer          not null, primary key
#  generated_at  :datetime
#  data_datetime :datetime
#  title         :string
#  source        :string
#  comm_type     :string
#  data_type     :string
#  data_imported :boolean
#  data_date     :date
#

module DataImportRecordYardiSpreadSheetTitle
  CobaltDailyReport = 'Cobalt Daily Report'
  RentChangeSuggestionReport = 'Rent Change Suggestion Report Summary w/ Reasons (w/ pending LA apps)'
  RedBotComplianceReport = 'Red Bot Compliance Report'
  APRedBotComplianceReport = 'AP Red Bot Compliance Report'
  CobaltAgentSalesReport = 'Cobalt Agent Sales Report'
  LeadsProblemReport = 'Leads Problem Report'
  RedbotMaintenanceReport = 'Redbot Maintenance Report'
  BluestoneWorkOrderIncompleteList = 'Bluestone Work Order Incomplete List'
  CobaltPortfolioSalesAddendum = 'Cobalt Portfolio Sales Addendum'
  CobaltUnknownDetailReport = 'Cobalt Unknown Detail Report'
  CobaltCollectionDetailReport = 'Cobalt Collection Detail Report'
  CobaltRentDetailReport = 'Cobalt Rent Detail Report'
  CompSurveyByBedSummary = 'Comp Survey By Bed Summary'
  CollectionsSnapshot = 'Collections Snapshot'
  CollectionsSnapshotByTenant = 'Collections Snapshot by Tenant'
end

module DataImportRecordCostarSpreadSheetTitle
  CostarMarketData = 'Costar Market Data'
end

module DataImportRecordManualSpreadSheetTitle
  DiversityInclusionCalendar = 'Diversity & Inclusion Calendar'
end

module DataImportRecordUltproJSONTitle
  PersonnelEmployeeDetails = 'Personnel: Employee Details'
  PersonnelPersonDetails = 'Personnel: Person Details'
end

module DataImportRecordWorkableJSONTitle
  Jobs = 'Jobs'
  JobActivities = 'Job Activities'
end

module DataImportRecordBlueskyJSONTitle
  ProspectStatsForAllProperties = 'Prospect Stats for All Properties'
end

module DataImportRecordSparkleJSONTitle
  LatestInspectionComplianceChecksForProperties = 'Latest Inspection Compliance Checks for Properties'
end

module DataImportRecordSource
  YARDI = 'Yardi'
  SPARKLE = 'Sparkle'
  COSTAR = 'Costar'
  BLUESKY = 'Bluesky'
  ULTIPRO = 'UltiPro'
  WORKABLE = 'Workable'
  MANUAL = 'Manual'
end

module DataImportRecordCommType
  EMAIL = 'Email'
  API = 'API'
end

module DataImportRecordDataType
  JSON = 'JSON'
  XML = 'XML'
  SPREADSHEET = 'SPREADSHEET'
  CSV = 'CSV'
end

class DataImportRecord < ActiveRecord::Base
  validates :generated_at, presence: true
  validates :title, presence: true
  validates :source, presence: true
  validates :comm_type, presence: true
  validates :data_type, presence: true
  validates :data_imported, inclusion: { in: [true, false] }

  def self.apiJSON(source: string, data_date: Date, data_datetime: DateTime, title: string)
    record = DataImportRecord.new
    record.source = source
    record.comm_type = DataImportRecordCommType::API
    record.data_type = DataImportRecordDataType::JSON
    record.title = title
    record.data_date = data_date
    record.data_datetime = data_datetime
    record.generated_at = DateTime.now

    return record
  end

  def self.emailSpreadsheet(source: string, data_date: Date, data_datetime: DateTime, title: string)
    record = DataImportRecord.new
    record.source = source
    record.comm_type = DataImportRecordCommType::EMAIL
    record.data_type = DataImportRecordDataType::SPREADSHEET
    record.title = title
    record.data_date = data_date
    record.data_datetime = data_datetime
    record.generated_at = DateTime.now

    return record
  end

  def self.lastImportByDataDate(source: string, title: string)
    return DataImportRecord.where(source: source, title: title).order("data_date DESC, generated_at DESC").first
  end

  def self.lastImportByDataDatetime(source: string, title: string)
    return DataImportRecord.where(source: source, title: title).order("data_datetime DESC, generated_at DESC").first
  end

  def self.lastImport(source: string, title: string)
    return DataImportRecord.where(source: source, title: title).order("generated_at DESC").first
  end

  def sendNoficationToSlack
    channel = "#cobalt-data-imports"
    data_imported_message = ''
    if !self.data_imported
      data_imported_message = ", *data threre was not*"
    end
    if self.data_date.present?
      message = "*#{self.source}* (#{self.data_date}) import there was#{data_imported_message}: `#{self.title}`"
    elsif self.data_datetime.present?
      message = "*#{self.source}* (#{self.data_datetime}) import there was#{data_imported_message}: `#{self.title}`"
    else  
      message = "*#{self.source}* import there was#{data_imported_message}: `#{self.title}`"
    end
    send_alert = Alerts::Commands::SendCorpYodaBotSlackMessage.new(message, channel)
    Job.create(send_alert)
  end


end

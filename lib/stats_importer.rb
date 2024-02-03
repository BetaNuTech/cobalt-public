require 'httparty'

class StatsImporter
  include HTTParty
  RECORD_CLASS = StatRecord

  class DefaultProcessor
    def call(record)
      record.data = JSON.parse(record.raw)
      record.generated_at = DateTime.now
      # TODO set record.generated_at based on data content
      return record
    end
  end

  class DruidProspectStatsProcessor
    def call(record)
      begin
        record.data = JSON.parse(record.raw)
      rescue
        record.data = {}
        record.success = false
      end
      record.generated_at = DateTime.now
      if record.data["Meta"].present? && record.data["Meta"]["ReportDate"].present?
        record.generated_at = Date.parse(record.data["Meta"]["ReportDate"])
      end
      return record
    end
  end

  def initialize(source:, name:, url:)
    @source = source
    @name = name
    @url = url
    @processor = select_processor
  end

  def perform
    begin
      http_response = HTTParty.get(@url)
      parsed = parse_response(http_response)
      record = build_record(parsed)
      record = process_record(record)
      remove_duplicate_records(record)
      record.save
    rescue Net::ReadTimeout => e
      Rails.logger.error("ERROR StatsImporter Timeout fetching data from #{url}")
      record = RECORD_CLASS.new
      record.validate
    end
    return record
  end

  private

  def build_record(data)
    record = RECORD_CLASS.new(
      source: @source,
      name: @name,
      url: @url,
      success: data[:success],
      raw: data[:data]
    )
    return record
  end

  def parse_response(response)
    result = {
      data: response.body,
      response: nil,
      success: nil
    }
    case response.code
    when 200
      result[:success] = true
      result[:response] = response.headers.inspect
    else
      result[:success] = false
      result[:response] = response.headers.inspect + "\n" + response.body
    end
    return result
  end

  def process_record(record)
    if record.success
      return @processor.call(record)
    else
      return record
    end
  end

  def select_processor
    # Return a processor class based on: @source, @name
    if @source == 'druid' && @name.end_with?("prospect_stats")
      return DruidProspectStatsProcessor.new
    end
      
    return DefaultProcessor.new
  end

  def remove_duplicate_records(record)
    # Return a processor class based on: @source, @name
    if record.success == true
      duplicate_records = RECORD_CLASS.where(source: record.source, name: record.name, generated_at: record.generated_at)
      if !duplicate_records.nil?
        duplicate_records.delete_all
      end
    else
      duplicate_failed_records = RECORD_CLASS.where(source: record.source, name: record.name, generated_at: record.generated_at, success: false)
      if !duplicate_failed_records.nil?
        duplicate_failed_records.delete_all
      end
    end      
  end

end

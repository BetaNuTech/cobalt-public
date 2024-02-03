module ApplicationHelper
  
  def formatted_date(date)
    if date.present?
      return date.strftime("%m/%d/%Y")
    else
      return nil
    end
  end

  # For bluebot_rollup_report view
  def end_of_month_selections(value=Date.today)
    earliest_end_month = Date.parse("December 2017").end_of_month # last set of 12 months of data
    latest_end_month = (Date.today + 1.day - 1.month).end_of_month
    num_of_months = (latest_end_month.year * 12 + latest_end_month.month) - (earliest_end_month.year * 12 + earliest_end_month.month)

    dates = (1..num_of_months+1).to_a.
      map{ |m| (Date.today + 1.day - m.months).end_of_month }.
      map{ |d| [d.strftime("%B %Y"), d] }
    selected_option = Date.parse(value.to_s).end_of_month
    options_for_select(dates, selected_option)
  end

  # For bluebot_agent_sales_rollup_report view
  def agent_sales_end_of_month_selections(value=Date.today)
    earliest_end_month = Date.parse("October 2017").end_of_month # last set of 12 months of data
    latest_end_month = (Date.today + 1.day - 1.month).end_of_month
    num_of_months = (latest_end_month.year * 12 + latest_end_month.month) - (earliest_end_month.year * 12 + earliest_end_month.month)

    dates = (1..num_of_months+1).to_a.
      map{ |m| (Date.today + 1.day - m.months).end_of_month }.
      map{ |d| [d.strftime("%B %Y"), d] }
    selected_option = Date.parse(value.to_s).end_of_month
    options_for_select(dates, selected_option)
  end

  def costar_market_data_date_selections(value=Date.today)
    import_dates = CostarMarketDatum.select(:date).distinct.order("date DESC").pluck(:date)
    if value == Date.today
      options_for_select(import_dates, import_dates.first)
    else    
      options_for_select(import_dates, value)
    end
  end

  def body_class
    [controller_name, action_name].join('-')
  end

  def retina_image_tag(uploader, version, options={})
    options.symbolize_keys!
    options[:srcset] ||=  (2..3).map do |multiplier|
      name = "#{version}_#{multiplier}x"
      if uploader.version_exists?(name) &&
        source = uploader.url(name).presence
        "#{source} #{multiplier}x"
      else
        nil
      end
    end.compact.join(', ')

    image_tag(uploader.url(version), options)
  end

  def show_svg(path)
    File.open("app/assets/images/#{path}", "rb") do |file|
      raw file.read
    end
  end

  def commontator_thread(thread)
    user = Commontator.current_user_proc.call(self)
    
    render(
      partial: 'commontator/shared/thread', locals: {
        user: user,
        thread: thread,
        page: 1,
        show_all: true
      }
    ).html_safe
  end

  def commontator_gravatar_image_tag(user, border = 1, options = {})
    email = Commontator.commontator_email(user) || ''
    name = Commontator.commontator_name(user) || ''

    base = request.ssl? ? "s://secure" : "://www"
    hash = Digest::MD5.hexdigest(email)
    url = "http#{base}.gravatar.com/avatar/#{hash}?#{options.to_query}"
    
    image_tag(url, { :alt => name,
                     :title => name,
                     :border => border })
  end

end

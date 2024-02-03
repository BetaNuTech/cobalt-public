class CostarMarketDataController < ApplicationController
  include ActionView::Helpers::NumberHelper
  include ApplicationHelper
  include ActionView::Helpers::OutputSafetyHelper
  
  # GET /costar_market_data/
  # GET /costar_market_data.json/
  def show
    import_date = params[:costar_market_data_form] ? Date.parse(params[:costar_market_data_form][:import_date].to_s) : Date.today
    @date_form = CostarMarketDataForm.new({import_date: import_date })

    respond_to do |format|
      format.html
      format.json do 
        render_datatables
      end
    end

  end
  
  private
  def render_datatables
    
    if @date_form.import_date == Date.today
      latest_date = CostarMarketDatum.select(:date).distinct.order("date DESC").pluck(:date).first
      if latest_date.present?
        @costar_market_data = CostarMarketDatum.where(date: latest_date)
      end
    else
      @costar_market_data = CostarMarketDatum.where(date: @date_form.import_date)
    end
    
    @data = create_data
    add_portfolio_data()
    add_data_for_teams()
    set_ordering

    data_tables = create_data_tables
    render json: data_tables.as_json
  end
  
  def create_data_tables
    data_tables = {
         data: create_table_data
       }
       
    return data_tables    
  end

  def create_data
    data = @costar_market_data.collect do |comp_datum|

      comp_occupancy = (1.0 - comp_datum.submarket_percent_vacant) * 100.0
      comp_basis = (1.0 - comp_datum.submarket_percent_vacant) * comp_datum.average_effective_rent

      comp_datum_oldest = CostarMarketDatum.where(property: comp_datum.property_id).where("date >= ?", comp_datum.date - 6.months).order("date ASC").first

      if comp_datum_oldest.present?
        rent_change = comp_datum.average_effective_rent.round(0) - comp_datum_oldest.average_effective_rent.round(0)
        rent_change_one_bedroom = comp_datum.one_bedroom_effective_rent.round(0) - comp_datum_oldest.one_bedroom_effective_rent.round(0)
        rent_change_two_bedroom = comp_datum.two_bedroom_effective_rent.round(0) - comp_datum_oldest.two_bedroom_effective_rent.round(0)
        rent_change_three_bedroom = comp_datum.three_bedroom_effective_rent.round(0) - comp_datum_oldest.three_bedroom_effective_rent.round(0)
        if comp_datum_oldest.average_effective_rent > 0
          percent_rent_change = (rent_change / comp_datum_oldest.average_effective_rent.round(0)) * 100.0
        end
        if comp_datum_oldest.one_bedroom_effective_rent > 0
          percent_rent_change_one_bedroom = (rent_change_one_bedroom / comp_datum_oldest.one_bedroom_effective_rent.round(0)) * 100.0
        end
        if comp_datum_oldest.two_bedroom_effective_rent > 0
          percent_rent_change_two_bedroom = (rent_change_two_bedroom / comp_datum_oldest.two_bedroom_effective_rent.round(0)) * 100.0
        end
        if comp_datum_oldest.three_bedroom_effective_rent > 0
          percent_rent_change_three_bedroom = (rent_change_three_bedroom / comp_datum_oldest.three_bedroom_effective_rent.round(0)) * 100.0
        end
      else 
        rent_change = 0
        rent_change_one_bedroom = 0
        rent_change_two_bedroom = 0
        rent_change_three_bedroom = 0
      end

      metric = Metric.where(property: comp_datum.property_id).where(date: comp_datum.date).first
      if metric.present?
        number_of_units = metric.number_of_units
        actual_occupancy = metric.physical_occupancy
        actual_average_effective_rent = metric.average_rents_net_effective
        actual_basis = (actual_occupancy / 100.0) * actual_average_effective_rent
        basis_variance = 100 + (((actual_basis - comp_basis) / actual_basis) * 100.0)

        actual_basis_color_level = 3
        if actual_basis.round(0) > comp_basis.round(0)
          actual_basis_color_level = 2
        elsif actual_basis.round(0) < comp_basis.round(0)
          actual_basis_color_level = 4
        end

        occupancy_color_level = 3
        if actual_occupancy.round(1) > comp_occupancy.round(1)
          occupancy_color_level = 2
        elsif actual_occupancy.round(1) < comp_occupancy.round(1)
          occupancy_color_level = 4
        end

        # overrides to property color
        property_color_level = actual_basis_color_level
        if actual_basis_color_level == 2 && occupancy_color_level == 2
          property_color_level = 1
        elsif actual_basis_color_level == 4 && occupancy_color_level == 4
          property_color_level = 5
        end

        average_effective_rent_color_level = 3
        if actual_average_effective_rent.round(0) > comp_datum.average_effective_rent.round(0)
          average_effective_rent_color_level = 2
        elsif actual_average_effective_rent.round(0) < comp_datum.average_effective_rent.round(0)
          average_effective_rent_color_level = 4
        end

        occupancy_delta = actual_occupancy - comp_occupancy
        average_effective_rent_delta = ((actual_average_effective_rent - comp_datum.average_effective_rent) / comp_datum.average_effective_rent) * 100.0
      else
        number_of_units = 0
        actual_occupancy = 0
        actual_average_effective_rent = 0
        occupancy_color_level = 3
        property_color_level = 3
        average_effective_rent_color_level = 3
        occupancy_delta = 0
        average_effective_rent_delta = 0
        actual_basis = 0
        basis_variance = 100
        actual_basis_color_level = 3
      end

      one_bed_detail = AverageRentsBedroomDetail.where(property: comp_datum.property_id, date: comp_datum.date, num_of_bedrooms: 1).first
      two_bed_detail = AverageRentsBedroomDetail.where(property: comp_datum.property_id, date: comp_datum.date, num_of_bedrooms: 2).first
      three_bed_detail = AverageRentsBedroomDetail.where(property: comp_datum.property_id, date: comp_datum.date, num_of_bedrooms: 3).first
      if one_bed_detail.present?
        actual_one_bedroom_effective_rent = one_bed_detail.net_effective_average_rent
        one_bedroom_effective_rent_color_level = 3
        if actual_one_bedroom_effective_rent.round(0) > comp_datum.one_bedroom_effective_rent.round(0)
          one_bedroom_effective_rent_color_level = 2
        elsif actual_one_bedroom_effective_rent.round(0) < comp_datum.one_bedroom_effective_rent.round(0)
          one_bedroom_effective_rent_color_level = 4
        end

        one_bedroom_effective_rent_delta = ((actual_one_bedroom_effective_rent - comp_datum.one_bedroom_effective_rent) / comp_datum.one_bedroom_effective_rent) * 100.0
      else
        actual_one_bedroom_effective_rent = 0
        one_bedroom_effective_rent_color_level = 3
        one_bedroom_effective_rent_delta = 0
      end

      if two_bed_detail.present?
        actual_two_bedroom_effective_rent = two_bed_detail.net_effective_average_rent
        two_bedroom_effective_rent_color_level = 3
        if actual_two_bedroom_effective_rent.round(0) > comp_datum.two_bedroom_effective_rent.round(0)
          two_bedroom_effective_rent_color_level = 2
        elsif actual_two_bedroom_effective_rent.round(0) < comp_datum.two_bedroom_effective_rent.round(0)
          two_bedroom_effective_rent_color_level = 4
        end

        two_bedroom_effective_rent_delta = ((actual_two_bedroom_effective_rent - comp_datum.two_bedroom_effective_rent) / comp_datum.two_bedroom_effective_rent) * 100.0
      else
        actual_two_bedroom_effective_rent = 0
        two_bedroom_effective_rent_color_level = 3
        two_bedroom_effective_rent_delta = 0
      end

      if three_bed_detail.present?
        actual_three_bedroom_effective_rent = three_bed_detail.net_effective_average_rent
        three_bedroom_effective_rent_color_level = 3
        if actual_three_bedroom_effective_rent.round(0) > comp_datum.three_bedroom_effective_rent.round(0)
          three_bedroom_effective_rent_color_level = 2
        elsif actual_three_bedroom_effective_rent.round(0) < comp_datum.three_bedroom_effective_rent.round(0)
          three_bedroom_effective_rent_color_level = 4
        end

        three_bedroom_effective_rent_delta = ((actual_three_bedroom_effective_rent - comp_datum.three_bedroom_effective_rent) / comp_datum.three_bedroom_effective_rent) * 100.0
      else
        actual_three_bedroom_effective_rent = 0
        three_bedroom_effective_rent_color_level = 3
        three_bedroom_effective_rent_delta = 0
      end

      survey_one_bed_detail = CompSurveyByBedDetail.where(property: comp_datum.property_id, num_of_bedrooms: 1).where("survey_date >= ?", comp_datum.date).order("date ASC").first
      survey_two_bed_detail = CompSurveyByBedDetail.where(property: comp_datum.property_id, num_of_bedrooms: 2).where("survey_date >= ?", comp_datum.date).order("date ASC").first
      survey_three_bed_detail = CompSurveyByBedDetail.where(property: comp_datum.property_id, num_of_bedrooms: 3).where("survey_date >= ?", comp_datum.date).order("date ASC").first

      if survey_one_bed_detail.present?
        survey_one_bedroom_rent = survey_one_bed_detail.comp_market_rent
        survey_date = survey_one_bed_detail.date - survey_one_bed_detail.days_since_last_survey.days
        survey_date = survey_date.to_s
      else
        survey_one_bed_detail = CompSurveyByBedDetail.where(property: comp_datum.property_id, num_of_bedrooms: 1).where("date >= ?", comp_datum.date).order("date ASC").first
        if survey_one_bed_detail.present?
          survey_one_bedroom_rent = survey_one_bed_detail.comp_market_rent
          survey_date = survey_one_bed_detail.date - survey_one_bed_detail.days_since_last_survey.days
          survey_date = survey_date.to_s
        else
          survey_one_bedroom_rent = 0
          survey_date = ""  
        end
      end

      if survey_two_bed_detail.present?
        survey_two_bedroom_rent = survey_two_bed_detail.comp_market_rent
      else
        survey_two_bed_detail = CompSurveyByBedDetail.where(property: comp_datum.property_id, num_of_bedrooms: 2).where("date >= ?", comp_datum.date).order("date ASC").first
        if survey_two_bed_detail.present?
          survey_two_bedroom_rent = survey_two_bed_detail.comp_market_rent
        else
          survey_two_bedroom_rent = 0
        end
      end

      if survey_three_bed_detail.present?
        survey_three_bedroom_rent = survey_three_bed_detail.comp_market_rent
      else
        survey_three_bed_detail = CompSurveyByBedDetail.where(property: comp_datum.property_id, num_of_bedrooms: 3).where("date >= ?", comp_datum.date).order("date ASC").first
        if survey_three_bed_detail.present?
          survey_three_bedroom_rent = survey_three_bed_detail.comp_market_rent
        else
          survey_three_bedroom_rent = 0
        end      
      end

      {
        :id => comp_datum.id,
        :property_code => comp_datum.property.code,
        :position => 2,
        :team_id => comp_datum.property.team_id,
        :property_color_level => property_color_level,
        :number_of_units => number_of_units,
        :comp_occupancy => comp_occupancy,
        :actual_occupancy => actual_occupancy,
        :occupancy_color_level => occupancy_color_level,
        :occupancy_delta => occupancy_delta,
        :average_effective_rent => comp_datum.average_effective_rent,
        :actual_average_effective_rent => actual_average_effective_rent,
        :average_effective_rent_color_level => average_effective_rent_color_level,
        :average_effective_rent_delta => average_effective_rent_delta,
        :comp_basis => comp_basis,
        :actual_basis => actual_basis,
        :basis_variance => basis_variance,
        :actual_basis_color_level => actual_basis_color_level,
        :one_bedroom_effective_rent => comp_datum.one_bedroom_effective_rent,
        :actual_one_bedroom_effective_rent => actual_one_bedroom_effective_rent,
        :one_bedroom_effective_rent_delta => one_bedroom_effective_rent_delta,
        :one_bedroom_effective_rent_color_level => one_bedroom_effective_rent_color_level,
        :two_bedroom_effective_rent => comp_datum.two_bedroom_effective_rent,
        :actual_two_bedroom_effective_rent => actual_two_bedroom_effective_rent,
        :two_bedroom_effective_rent_color_level => two_bedroom_effective_rent_color_level,
        :two_bedroom_effective_rent_delta => two_bedroom_effective_rent_delta,
        :three_bedroom_effective_rent => comp_datum.three_bedroom_effective_rent,
        :actual_three_bedroom_effective_rent => actual_three_bedroom_effective_rent,
        :three_bedroom_effective_rent_color_level => three_bedroom_effective_rent_color_level,
        :three_bedroom_effective_rent_delta => three_bedroom_effective_rent_delta,
        :rent_change => rent_change,
        :rent_change_one_bedroom => rent_change_one_bedroom,
        :rent_change_two_bedroom => rent_change_two_bedroom,
        :rent_change_three_bedroom => rent_change_three_bedroom,
        :percent_rent_change => percent_rent_change,
        :percent_rent_change_one_bedroom => percent_rent_change_one_bedroom,
        :percent_rent_change_two_bedroom => percent_rent_change_two_bedroom,
        :percent_rent_change_three_bedroom => percent_rent_change_three_bedroom,
        :survey_date => survey_date,
        :survey_one_bedroom_rent => survey_one_bedroom_rent,
        :survey_two_bedroom_rent => survey_two_bedroom_rent,
        :survey_three_bedroom_rent => survey_three_bedroom_rent,
        :in_development => comp_datum.in_development
      }
    end    
    
    return data
  end

  def add_portfolio_data
    total_number_of_units = 0
    total_unit_comp_occupancy = 0
    total_unit_comp_effective_rent = 0

    @data.each do |datum|
      total_number_of_units += datum[:number_of_units]
      total_unit_comp_occupancy += datum[:comp_occupancy] * datum[:number_of_units]
      total_unit_comp_effective_rent += datum[:average_effective_rent] * datum[:number_of_units]
    end

    comp_occupancy = 0
    if total_number_of_units > 0
      comp_occupancy = total_unit_comp_occupancy / total_number_of_units
    end
    comp_effective_rent = 0
    if total_number_of_units > 0
      comp_effective_rent = total_unit_comp_effective_rent / total_number_of_units
    end

    comp_basis = (comp_occupancy / 100.0) * comp_effective_rent

    portfolio_data = {
      :property_code => Property.portfolio_code(),
      :property_color_level => 0,
      :position => 0,
      :basis_variance => 0,
      :comp_occupancy => comp_occupancy,
      :actual_occupancy => 0,
      :average_effective_rent => comp_effective_rent,
      :comp_basis => comp_basis,
      :rent_change => 0,
      :actual_average_effective_rent => 0,
      :one_bedroom_effective_rent => 0,
      :rent_change_one_bedroom => 0,
      :actual_one_bedroom_effective_rent => 0,
      :two_bedroom_effective_rent => 0,
      :rent_change_two_bedroom => 0,
      :actual_two_bedroom_effective_rent => 0,
      :three_bedroom_effective_rent => 0,
      :rent_change_three_bedroom => 0,
      :actual_three_bedroom_effective_rent => 0,
      :survey_date => "",
      :survey_one_bedroom_rent => 0,
      :survey_two_bedroom_rent => 0,
      :survey_three_bedroom_rent => 0,
      :in_development => false
    }

    @data.push portfolio_data
  end

  def add_data_for_teams
    teams = Property.teams.where(active: true).each do |team|
      total_number_of_units = 0
      total_unit_comp_occupancy = 0
      total_unit_comp_effective_rent = 0
  
      @data.each do |datum|
        if datum[:team_id].present? && datum[:team_id] == team.id
          total_number_of_units += datum[:number_of_units]
          total_unit_comp_occupancy += datum[:comp_occupancy] * datum[:number_of_units]
          total_unit_comp_effective_rent += datum[:average_effective_rent] * datum[:number_of_units]
        end
      end
  
      comp_occupancy = 0
      if total_number_of_units > 0
        comp_occupancy = total_unit_comp_occupancy / total_number_of_units
      end
      comp_effective_rent = 0
      if total_number_of_units > 0
        comp_effective_rent = total_unit_comp_effective_rent / total_number_of_units
      end
  
      comp_basis = (comp_occupancy / 100.0) * comp_effective_rent
  
      team_data = {
        :property_code => team.code,
        :property_color_level => 0,
        :position => 1,
        :basis_variance => 0,
        :comp_occupancy => comp_occupancy,
        :actual_occupancy => 0,
        :average_effective_rent => comp_effective_rent,
        :comp_basis => comp_basis,
        :rent_change => 0,
        :actual_average_effective_rent => 0,
        :one_bedroom_effective_rent => 0,
        :rent_change_one_bedroom => 0,
        :actual_one_bedroom_effective_rent => 0,
        :two_bedroom_effective_rent => 0,
        :rent_change_two_bedroom => 0,
        :actual_two_bedroom_effective_rent => 0,
        :three_bedroom_effective_rent => 0,
        :rent_change_three_bedroom => 0,
        :actual_three_bedroom_effective_rent => 0,
        :survey_date => "",
        :survey_one_bedroom_rent => 0,
        :survey_two_bedroom_rent => 0,
        :survey_three_bedroom_rent => 0,
        :in_development => false
      }
  
      @data.push team_data
    end
  end

  
  def create_table_data
    table_data = @data.collect do |comp_datum| 
      if comp_datum[:in_development] == true
        svg_link = "<svg class=\"in_development_svg_construction_hat\">#{show_svg('helmet-construction-svgrepo-com.svg')}</svg>"
        in_development_html = "<span class='in_development'>#{svg_link}</span>"
      else
        in_development_html = ''  
      end  

      [
        "<input class='costar_market_datum_id' type='hidden' value='#{comp_datum[:id]}'><input class='date' type='hidden' value='#{@date_form.import_date}'>#{in_development_html}<span class='costar-level-#{comp_datum[:property_color_level]}'>#{comp_datum[:property_code]}</span>",
        "<span>#{number(comp_datum[:basis_variance])}% (#{money(comp_datum[:comp_basis])} / <span class='costar-level-#{comp_datum[:actual_basis_color_level]}'>#{money(comp_datum[:actual_basis])}</span>)</span>",
        "<span >#{number(comp_datum[:comp_occupancy])}%</span>",
        "<span class='costar-level-#{comp_datum[:occupancy_color_level]}'>#{number(comp_datum[:actual_occupancy])}% (#{number(comp_datum[:occupancy_delta])}%)</span>",
        "<span>#{money(comp_datum[:average_effective_rent])}</span>",
        "<span>#{money(comp_datum[:rent_change])} (#{number(comp_datum[:percent_rent_change])}%)</span>",
        "<span class='costar-level-#{comp_datum[:average_effective_rent_color_level]}'>#{money(comp_datum[:actual_average_effective_rent])} (#{number(comp_datum[:average_effective_rent_delta])}%)</span>",
        "<span>#{money(comp_datum[:one_bedroom_effective_rent])}</span>",
        "<span>#{money(comp_datum[:rent_change_one_bedroom])} (#{number(comp_datum[:percent_rent_change_one_bedroom])}%)</span>",
        "<span class='costar-level-#{comp_datum[:one_bedroom_effective_rent_color_level]}'>#{money(comp_datum[:actual_one_bedroom_effective_rent])} (#{number(comp_datum[:one_bedroom_effective_rent_delta])}%)</span>",
        "<span>#{money(comp_datum[:two_bedroom_effective_rent])}</span>",
        "<span>#{money(comp_datum[:rent_change_two_bedroom])} (#{number(comp_datum[:percent_rent_change_two_bedroom])}%)</span>",
        "<span class='costar-level-#{comp_datum[:two_bedroom_effective_rent_color_level]}'>#{money(comp_datum[:actual_two_bedroom_effective_rent])} (#{number(comp_datum[:two_bedroom_effective_rent_delta])}%)</span>",
        "<span>#{money(comp_datum[:three_bedroom_effective_rent])}</span>",
        "<span>#{money(comp_datum[:rent_change_three_bedroom])} (#{number(comp_datum[:percent_rent_change_three_bedroom])}%)</span>",
        "<span class='costar-level-#{comp_datum[:three_bedroom_effective_rent_color_level]}'>#{money(comp_datum[:actual_three_bedroom_effective_rent])} (#{number(comp_datum[:three_bedroom_effective_rent_delta])}%)</span>",
        "<span>#{comp_datum[:survey_date]}</span>",
        "<span>#{money(comp_datum[:survey_one_bedroom_rent])}</span>",
        "<span>#{money(comp_datum[:survey_two_bedroom_rent])}</span>",
        "<span>#{money(comp_datum[:survey_three_bedroom_rent])}</span>"
      ]
    end    
    
    return table_data
  end

  def get_sort_column
    columns = %w[property_code
      basis_variance
      comp_occupancy
      actual_occupancy
      average_effective_rent
      rent_change
      actual_average_effective_rent
      one_bedroom_effective_rent
      rent_change_one_bedroom
      actual_one_bedroom_effective_rent
      two_bedroom_effective_rent
      rent_change_two_bedroom
      actual_two_bedroom_effective_rent
      three_bedroom_effective_rent
      rent_change_three_bedroom
      actual_three_bedroom_effective_rent
      survey_date
      survey_one_bedroom_rent
      survey_two_bedroom_rent
      survey_three_bedroom_rent
    ]
      
    unless params["order"].nil? || params["order"]["0"]["column"].nil?
      return columns[params["order"]["0"]["column"].to_i]
    end
      
    return columns[0]
  end

  def sort_direction
    unless params["order"].nil? || params["order"]["0"]["dir"].nil?
      return params["order"]["0"]["dir"] 
    end

    return 'asc'
  end  
  
  def set_ordering
    sort_column = get_sort_column

    direction = 1
    if sort_direction == "desc"
      direction = -1
    end
    
    if sort_column == 'property_code' and params['property_sort_cycle'] == "0"
      @data = @data.sort_by { |row| [row[:position], row[:property_code]]  }
    elsif sort_column == 'property_code' and params['property_sort_cycle'] == "1"
      @data = @data.sort_by { |row| [row[:position], -row[:property_color_level], row[:property_code]]  }
    elsif sort_column == 'property_code' and params['property_sort_cycle'] == "2"
      @data = @data.sort_by { |row| [row[:position], row[:property_color_level], row[:property_code]]  }
    elsif sort_column == 'basis_variance'
      @data = @data.sort_by { |row| [row[:position], row[:basis_variance] * direction, row[:property_code]]  }
    elsif sort_column == 'comp_occupancy'
      @data = @data.sort_by { |row| [row[:position], row[:comp_occupancy] * direction, row[:property_code]]  }
    elsif sort_column == 'actual_occupancy'
      @data = @data.sort_by { |row| [row[:position], row[:actual_occupancy] * direction, row[:property_code]]  }
    elsif sort_column == 'average_effective_rent'
      @data = @data.sort_by { |row| [row[:position], row[:average_effective_rent] * direction, row[:property_code]]  }
    elsif sort_column == 'rent_change'
      @data = @data.sort_by { |row| [row[:position], row[:rent_change] * direction, row[:property_code]]  }
    elsif sort_column == 'actual_average_effective_rent'
      @data = @data.sort_by { |row| [row[:position], row[:actual_average_effective_rent] * direction, row[:property_code]]  }
    elsif sort_column == 'one_bedroom_effective_rent'
      @data = @data.sort_by { |row| [row[:position], row[:one_bedroom_effective_rent] * direction, row[:property_code]]  }
    elsif sort_column == 'rent_change_one_bedroom'
      @data = @data.sort_by { |row| [row[:position], row[:rent_change_one_bedroom] * direction, row[:property_code]]  }
    elsif sort_column == 'actual_one_bedroom_effective_rent'
      @data = @data.sort_by { |row| [row[:position], row[:actual_one_bedroom_effective_rent] * direction, row[:property_code]]  }
    elsif sort_column == 'two_bedroom_effective_rent'
      @data = @data.sort_by { |row| [row[:position], row[:two_bedroom_effective_rent] * direction, row[:property_code]]  }
    elsif sort_column == 'rent_change_two_bedroom'
      @data = @data.sort_by { |row| [row[:position], row[:rent_change_two_bedroom] * direction, row[:property_code]]  }
    elsif sort_column == 'actual_two_bedroom_effective_rent'
      @data = @data.sort_by { |row| [row[:position], row[:actual_two_bedroom_effective_rent] * direction, row[:property_code]]  }
    elsif sort_column == 'three_bedroom_effective_rent'
      @data = @data.sort_by { |row| [row[:position], row[:three_bedroom_effective_rent] * direction, row[:property_code]]  }
    elsif sort_column == 'rent_change_three_bedroom'
      @data = @data.sort_by { |row| [row[:position], row[:rent_change_three_bedroom] * direction, row[:property_code]]  }
    elsif sort_column == 'actual_three_bedroom_effective_rent'
      @data = @data.sort_by { |row| [row[:position], row[:actual_three_bedroom_effective_rent] * direction, row[:property_code]]  }
    elsif sort_column == 'survey_date'
      @data = @data.sort_by { |row| [row[:position], row[:survey_date], row[:property_code]] }
    elsif sort_column == 'survey_one_bedroom_rent'
      @data = @data.sort_by { |row| [row[:position], row[:survey_one_bedroom_rent] * direction, row[:property_code]]  }
    elsif sort_column == 'survey_two_bedroom_rent'
      @data = @data.sort_by { |row| [row[:position], row[:survey_two_bedroom_rent] * direction, row[:property_code]]  }
    elsif sort_column == 'survey_three_bedroom_rent'
      @data = @data.sort_by { |row| [row[:position], row[:survey_three_bedroom_rent] * direction, row[:property_code]]  }
    else
      @data = @data.sort_by { |row| [row[:position], row[:property_code]] }
    end

  end
  
  def number(value)
    number_with_precision(value, precision: 1, strip_insignificant_zeros: true)  
  end

  def money(value)
    number_to_currency(value, precision: 0, strip_insignificant_zeros: true)  
  end
  
  def percent(value)
    number_to_percentage(value, precision: 1, strip_insignificant_zeros: true)
  end


end

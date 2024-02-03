require 'httparty'

class PropertyUnitsController < ApplicationController
  include ActionView::Helpers::NumberHelper
  
  def show
    if params[:property_id].present?
      property_id = params[:property_id]
      @property = Property.find(property_id)
    elsif params[:property_code].present?
      property_code = params[:property_code]
      @property = Property.where(code: property_code).first
    end

    if @property.nil?
      return
    end
    is_portfolio = @property.code == Property.portfolio_code ? true : false
    is_team = @property.type == 'Team' ? true : false
    
    set_sorting_data()

    if is_portfolio
      @units = sort_units(units: PropertyUnit.where(model: false))
    elsif is_team
      team_property_codes = Property.properties.where(active: true, team_id: @property).pluck('id')
      @units = sort_units(units: PropertyUnit.where(model: false, property: team_property_codes))
    else 
      @units = sort_units(units: PropertyUnit.where(model: false, property: @property))
    end

    @is_multiple_properties = is_portfolio || is_team

    @stats = calc_stats(units: @units)

    @property_code_options = Property.teams.where(active: true).order("code ASC").pluck('code')
    @property_code_options += Property.properties.where(active: true).where.not(code: Property.portfolio_code).order("code ASC").pluck('code')
  end
  
  private
  
  def calc_stats(units:)
    days_vacant_sum = 0
    days_vacant_units = 0
    avg_days_vacant = "No Data"

    days_vacant_to_ready_sum = 0
    days_vacant_to_ready_units = 0
    avg_days_vacant_to_ready = "No Data"

    days_ready_to_leased_sum = 0
    days_ready_to_leased_units = 0
    avg_days_ready_to_leased = "No Data"

    days_ready_to_occupied_sum = 0
    days_ready_to_occupied_units = 0
    avg_days_ready_to_occupied = "No Data"

    num_of_vacant_rented = 0
    num_of_vacant_unrented = 0
    num_of_notice_rented = 0
    num_of_notice_unrented = 0

    units.each do |unit|
      if unit.occupancy == 'vacant'
        if unit.lease_status != 'leased' && unit.lease_status != 'leased_reserved'
          num_of_vacant_unrented += 1
        else 
          num_of_vacant_rented += 1
        end
      else 
        if unit.lease_status == 'on_notice'
          num_of_notice_unrented += 1
        elsif unit.lease_status == 'leased_reserved'
          num_of_notice_rented += 1
        end
      end
      
      if unit.days_vacant.present?
        days_vacant_sum += unit.days_vacant
        days_vacant_units += 1
      elsif unit.prev_days_vacant.present?
        days_vacant_sum += unit.prev_days_vacant
        days_vacant_units += 1
      end

      if unit.days_vacant_to_ready.present?
        days_vacant_to_ready_sum += unit.days_vacant_to_ready
        days_vacant_to_ready_units += 1
      elsif unit.prev_days_vacant_to_ready.present?
        days_vacant_to_ready_sum += unit.prev_days_vacant_to_ready
        days_vacant_to_ready_units += 1
      end

      if unit.days_ready_to_leased.present?
        days_ready_to_leased_sum += unit.days_ready_to_leased
        days_ready_to_leased_units += 1
      elsif unit.prev_days_ready_to_leased.present?
        days_ready_to_leased_sum += unit.prev_days_ready_to_leased
        days_ready_to_leased_units += 1
      end

      if unit.days_ready_to_occupied.present?
        days_ready_to_occupied_sum += unit.days_ready_to_occupied
        days_ready_to_occupied_units += 1
      elsif unit.prev_days_ready_to_occupied.present?
        days_ready_to_occupied_sum += unit.prev_days_ready_to_occupied
        days_ready_to_occupied_units += 1
      end
    end

    if days_vacant_units > 0
      avg_days_vacant = "#{(days_vacant_sum.to_f / days_vacant_units.to_f).round(1)}"
    end
    if days_vacant_to_ready_units > 0
      avg_days_vacant_to_ready = "#{(days_vacant_to_ready_sum.to_f / days_vacant_to_ready_units.to_f).round(1)}"
    end
    if days_ready_to_leased_units > 0
      avg_days_ready_to_leased = "#{(days_ready_to_leased_sum.to_f / days_ready_to_leased_units.to_f).round(1)}"
    end
    if days_ready_to_occupied_units > 0
      avg_days_ready_to_occupied = "#{(days_ready_to_occupied_sum.to_f / days_ready_to_occupied_units.to_f).round(1)}"
    end

    return {:num_of_vacant_rented => num_of_vacant_rented, :num_of_vacant_unrented => num_of_vacant_unrented, :num_of_notice_rented => num_of_notice_rented, :num_of_notice_unrented => num_of_notice_unrented, :avg_days_vacant => avg_days_vacant, :avg_days_vacant_to_ready => avg_days_vacant_to_ready, :avg_days_ready_to_leased => avg_days_ready_to_leased, :avg_days_ready_to_occupied => avg_days_ready_to_occupied}
  end

  def set_sorting_data
    if params[:sort_default].nil?
      @sort_default = true
    else  
      @sort_default = params[:sort_default] == 'true' ? true : false
    end

    @sort_options = [
      'unit', 
      'unit_type', 
      'occupancy', 
      'status', 
      'rent_ready', 
      'market_rent', 
      'days_vacant', 
      'days_vacant_to_ready',
      'days_ready_to_leased',
      'days_ready_to_occupied'
    ]

    # Defaults
    @sort_by_unit_uri = "?property_id=#{@property.id}&sort_by=#{@sort_options[0]}&sort_default=true"
    @sort_by_unit_type_uri = "?property_id=#{@property.id}&sort_by=#{@sort_options[1]}&sort_default=true"
    @sort_by_occupancy_uri = "?property_id=#{@property.id}&sort_by=#{@sort_options[2]}&sort_default=true"
    @sort_by_status_uri = "?property_id=#{@property.id}&sort_by=#{@sort_options[3]}&sort_default=true"
    @sort_by_rent_ready_uri = "?property_id=#{@property.id}&sort_by=#{@sort_options[4]}&sort_default=true"
    @sort_by_market_rent_uri = "?property_id=#{@property.id}&sort_by=#{@sort_options[5]}&sort_default=true"
    @sort_by_days_vacant_uri = "?property_id=#{@property.id}&sort_by=#{@sort_options[6]}&sort_default=true"
    @sort_by_days_vacant_to_ready_uri = "?property_id=#{@property.id}&sort_by=#{@sort_options[7]}&sort_default=true"
    @sort_by_days_ready_to_leased_uri = "?property_id=#{@property.id}&sort_by=#{@sort_options[8]}&sort_default=true"
    @sort_by_days_ready_to_occupied_uri = "?property_id=#{@property.id}&sort_by=#{@sort_options[9]}&sort_default=true"

    # sort_default_reversed = @sort_default == false ? true : false
    sort_default_reversed = !@sort_default

    if params[:sort_by].present?
      case params[:sort_by]
      when @sort_options[0]
        @sort_option_selected = params[:sort_by]
        # Reverse direction
        @sort_by_unit_uri = "?property_id=#{@property.id}&sort_by=#{params[:sort_by]}&sort_default=#{sort_default_reversed}"
      when @sort_options[1]
        @sort_option_selected = params[:sort_by]
        # Reverse direction
        @sort_by_unit_type_uri = "?property_id=#{@property.id}&sort_by=#{params[:sort_by]}&sort_default=#{sort_default_reversed}"
      when @sort_options[2]
        @sort_option_selected = params[:sort_by]
        # Reverse direction
        @sort_by_occupancy_uri = "?property_id=#{@property.id}&sort_by=#{params[:sort_by]}&sort_default=#{sort_default_reversed}"
      when @sort_options[3]
        @sort_option_selected = params[:sort_by]
        # Reverse direction
        @sort_by_status_uri = "?property_id=#{@property.id}&sort_by=#{params[:sort_by]}&sort_default=#{sort_default_reversed}"
      when @sort_options[4]
        @sort_option_selected = params[:sort_by]
        # Reverse direction
        @sort_by_rent_ready_uri = "?property_id=#{@property.id}&sort_by=#{params[:sort_by]}&sort_default=#{sort_default_reversed}"
      when @sort_options[5]
        @sort_option_selected = params[:sort_by]
        # Reverse direction
        @sort_by_market_rent_uri = "?property_id=#{@property.id}&sort_by=#{params[:sort_by]}&sort_default=#{sort_default_reversed}"
      when @sort_options[6]
        @sort_option_selected = params[:sort_by]
        # Reverse direction
        @sort_by_days_vacant_uri = "?property_id=#{@property.id}&sort_by=#{params[:sort_by]}&sort_default=#{sort_default_reversed}"
      when @sort_options[7]
        @sort_option_selected = params[:sort_by]
        # Reverse direction
        @sort_by_days_vacant_to_ready_uri = "?property_id=#{@property.id}&sort_by=#{params[:sort_by]}&sort_default=#{sort_default_reversed}"
      when @sort_options[8]
        @sort_option_selected = params[:sort_by]
        # Reverse direction
        @sort_by_days_ready_to_leased_uri = "?property_id=#{@property.id}&sort_by=#{params[:sort_by]}&sort_default=#{sort_default_reversed}"
      when @sort_options[9]
        @sort_option_selected = params[:sort_by]
        # Reverse direction
        @sort_by_days_ready_to_occupied_uri = "?property_id=#{@property.id}&sort_by=#{params[:sort_by]}&sort_default=#{sort_default_reversed}"
      else
        @sort_option_selected = params[:sort_by]
        # Reverse direction
        @sort_by_unit_uri = "?property_id=#{@property.id}&sort_by=#{params[:sort_by]}&sort_default=#{sort_default_reversed}"
      end
    else
      @sort_option_selected = @sort_options[0]
      # Reverse direction
      @sort_by_unit_uri = "?property_id=#{@property.id}&sort_by=#{params[:sort_by]}&sort_default=#{sort_default_reversed}"
    end
  end

  def sort_units(units:)
    # @sort_options = ['unit', 'unit_type', 'occupancy', 'status', 'rent_ready', 'market_rent', 'days_vacant']
    
    case @sort_option_selected
    when @sort_options[0] # Unit
      if @sort_default == true
        return units.sort do |a, b|
          comp = (a.property.code <=> b.property.code)
          if comp.zero?
            a.name.to_i <=> b.name.to_i
          else 
            comp
          end
        end
      else 
        return units.sort do |b, a|
          comp = (a.property.code <=> b.property.code)
          if comp.zero?
            a.name.to_i <=> b.name.to_i
          else 
            comp
          end
        end 
      end
    when @sort_options[1] # Unit Type
      if @sort_default == true
        return units.sort { |a,b| a.unit_type <=> b.unit_type }
      else   
        return units.sort { |b,a| a.unit_type <=> b.unit_type }
      end
    # when @sort_options[2] # Bedrooms/Bathrooms
    #   return units.sort do |a, b|
    #     comp = (b.bedrooms <=> a.bedrooms)
    #     if comp.zero?
    #       b.bathrooms <=> a.bathrooms
    #     else 
    #       comp
    #     end
    #   end
    when @sort_options[2] # Occupancy
      if @sort_default == true
        return units.sort { |a,b| b.occupancy <=> a.occupancy }
      else  
        return units.sort { |b,a| b.occupancy <=> a.occupancy }
      end
    when @sort_options[3] # Lease Status
      if @sort_default == true
        return units.sort { |a,b| a.lease_status <=> b.lease_status }
      else  
        return units.sort { |b,a| a.lease_status <=> b.lease_status }
      end
    when @sort_options[4] # Rent Ready
      if @sort_default == true
        return units.sort { |a| a.rent_ready ? 1 : -1 }
      else  
        return units.sort { |a| a.rent_ready ? -1 : 1 }
      end
    when @sort_options[5] # Market Rent
      if @sort_default == true
        return units.sort { |a,b| b.market_rent <=> a.market_rent }
      else  
        return units.sort { |b,a| b.market_rent <=> a.market_rent }
      end
    when @sort_options[6] # Days Vacant
      if @sort_default == true
        return units.sort do |a,b| 
          a_val = a.days_vacant.nil? ? a.prev_days_vacant.nil? ? -1 : a.prev_days_vacant : a.days_vacant
          b_val = b.days_vacant.nil? ? b.prev_days_vacant.nil? ? -1 : b.prev_days_vacant : b.days_vacant
          a_val <=> b_val
        end
      else  
        return units.sort do |b,a| 
          a_val = a.days_vacant.nil? ? a.prev_days_vacant.nil? ? -1 : a.prev_days_vacant : a.days_vacant
          b_val = b.days_vacant.nil? ? b.prev_days_vacant.nil? ? -1 : b.prev_days_vacant : b.days_vacant
          a_val <=> b_val
        end
      end
    when @sort_options[7] # Days Vacant to Ready
      if @sort_default == true
        return units.sort do |a,b| 
          a_val = a.days_vacant_to_ready.nil? ? a.prev_days_vacant_to_ready.nil? ? -1 : a.prev_days_vacant_to_ready : a.days_vacant_to_ready
          b_val = b.days_vacant_to_ready.nil? ? b.prev_days_vacant_to_ready.nil? ? -1 : b.prev_days_vacant_to_ready : b.days_vacant_to_ready
          a_val <=> b_val
        end
      else  
        return units.sort do |b,a| 
          a_val = a.days_vacant_to_ready.nil? ? a.prev_days_vacant_to_ready.nil? ? -1 : a.prev_days_vacant_to_ready : a.days_vacant_to_ready
          b_val = b.days_vacant_to_ready.nil? ? b.prev_days_vacant_to_ready.nil? ? -1 : b.prev_days_vacant_to_ready : b.days_vacant_to_ready
          a_val <=> b_val
        end
      end
    when @sort_options[8] # Days Ready to Leased
      if @sort_default == true
        return units.sort do |a,b| 
          a_val = a.days_ready_to_leased.nil? ? a.prev_days_ready_to_leased.nil? ? -1 : a.prev_days_ready_to_leased : a.days_ready_to_leased
          b_val = b.days_ready_to_leased.nil? ? b.prev_days_ready_to_leased.nil? ? -1 : b.prev_days_ready_to_leased : b.days_ready_to_leased
          a_val <=> b_val
        end
      else  
        return units.sort do |b,a| 
          a_val = a.days_ready_to_leased.nil? ? a.prev_days_ready_to_leased.nil? ? -1 : a.prev_days_ready_to_leased : a.days_ready_to_leased
          b_val = b.days_ready_to_leased.nil? ? b.prev_days_ready_to_leased.nil? ? -1 : b.prev_days_ready_to_leased : b.days_ready_to_leased
          a_val <=> b_val
        end
      end
    when @sort_options[9] # Days Ready to Occupied
      if @sort_default == true
        return units.sort do |a,b| 
          a_val = a.days_ready_to_occupied.nil? ? a.prev_days_ready_to_occupied.nil? ? -1 : a.prev_days_ready_to_occupied : a.days_ready_to_occupied
          b_val = b.days_ready_to_occupied.nil? ? b.prev_days_ready_to_occupied.nil? ? -1 : b.prev_days_ready_to_occupied : b.days_ready_to_occupied
          a_val <=> b_val
        end
      else  
        return units.sort do |b,a| 
          a_val = a.days_ready_to_occupied.nil? ? a.prev_days_ready_to_occupied.nil? ? -1 : a.prev_days_ready_to_occupied : a.days_ready_to_occupied
          b_val = b.days_ready_to_occupied.nil? ? b.prev_days_ready_to_occupied.nil? ? -1 : b.prev_days_ready_to_occupied : b.days_ready_to_occupied
          a_val <=> b_val
        end
      end
    else
      if @sort_default == true
        return units.sort do |a, b|
          comp = (a.property.code <=> b.property.code)
          if comp.zero?
            a.name.to_i <=> b.name.to_i
          else 
            comp
          end
        end
      else 
        return units.sort do |b, a|
          comp = (a.property.code <=> b.property.code)
          if comp.zero?
            a.name.to_i <=> b.name.to_i
          else 
            comp
          end
        end 
      end
    end
  end


  def percent(value)
    number_to_percentage(value, precision: 0, strip_insignificant_zeros: true)
  end

  def money(value)
    number_to_currency(value, precision: 2, strip_insignificant_zeros: false)  
  end

end

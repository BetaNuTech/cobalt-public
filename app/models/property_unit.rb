# == Schema Information
#
# Table name: property_units
#
#  id                             :integer          not null, primary key
#  property_id                    :integer
#  model                          :boolean
#  remoteid                       :string
#  name                           :string
#  bedrooms                       :integer
#  bathrooms                      :integer
#  sqft                           :integer
#  occupancy                      :string
#  lease_status                   :string
#  vacate_on                      :date
#  made_ready_on                  :date
#  market_rent                    :float
#  unit_type                      :string
#  floorplan_name                 :string
#  rent_ready                     :boolean
#  days_vacant                    :integer
#  days_vacant_to_ready           :integer
#  days_ready_to_leased           :integer
#  days_ready_to_occupied         :integer
#  prev_days_vacant               :integer
#  prev_days_vacant_to_ready      :integer
#  prev_days_ready_to_leased      :integer
#  prev_days_ready_to_occupied    :integer
#  data_start_datetime            :datetime
#  occupied_start_datetime        :datetime
#  occupied_end_datetime          :datetime
#  vacant_start_datetime          :datetime
#  vacant_end_datetime            :datetime
#  rent_ready_start_datetime      :datetime
#  rent_ready_end_datetime        :datetime
#  leased_start_datetime          :datetime
#  leased_end_datetime            :datetime
#  occupied_prev_start_datetime   :datetime
#  occupied_prev_end_datetime     :datetime
#  vacant_prev_start_datetime     :datetime
#  vacant_prev_end_datetime       :datetime
#  rent_ready_prev_start_datetime :datetime
#  rent_ready_prev_end_datetime   :datetime
#  leased_prev_start_datetime     :datetime
#  leased_prev_end_datetime       :datetime
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#
class PropertyUnit < ActiveRecord::Base
  belongs_to :property
  validates :property, presence: true
  validates :remoteid, presence: true
  validates :unit_type, presence: true
  validates :occupancy, presence: true
  validates :lease_status, presence: true
  validates :rent_ready, inclusion: { in: [true, false] }

  # Yardi Voyager Data Unit Import
  def self.import_yardi_unit_data(property, unit_data) 
    # These are not actually units, but way to have waitlist for prospects
    if unit_data.remoteid.downcase.include? 'wait'
      if PropertyUnit.where(property: property, remoteid: unit_data.remoteid).first.present?
        # Remove any already stored in the database
        PropertyUnit.where(property: property, remoteid: unit_data.remoteid).first.destroy
      end
      return false
    end

    unit = PropertyUnit.where(property: property, remoteid: unit_data.remoteid).first_or_initialize

    # Set Unit data
    unit.property = property
    unit.model = unit_data.model
    unit.remoteid = unit_data.remoteid

    unit.name = unit_data.name
    unit.bedrooms = unit_data.bedrooms
    unit.bathrooms = unit_data.bathrooms
    unit.sqft = unit_data.sqft
    unit.occupancy = unit_data.occupancy
    unit.lease_status = unit_data.lease_status
    unit.vacate_on = unit_data.vacate_on
    unit.made_ready_on = unit_data.made_ready_on
    unit.market_rent = unit_data.market_rent
    unit.unit_type = unit_data.unit_type
    unit.floorplan_name = unit_data.floorplan_name
    unit.rent_ready = unit_data.rent_ready

    currentDateTime = DateTime.now

    if unit.data_start_datetime.nil?
      unit.data_start_datetime = currentDateTime
    end

    # Set Start/End for Occupancy
    # Reset previous windows
    # Store previous vacant start/end, and previous occupied start/end, for previous stats
    if    unit_data.occupancy == 'occupied'
      if unit.occupied_start_datetime.nil?
        if unit.vacant_start_datetime.present?
          unit.vacant_prev_start_datetime = unit.vacant_start_datetime
          unit.vacant_start_datetime = nil
        end
        if unit.vacant_end_datetime.present?
          unit.vacant_prev_end_datetime = unit.vacant_end_datetime
          unit.vacant_end_datetime = nil
        end
        unit.occupied_start_datetime = currentDateTime
      else  
        unit.occupied_end_datetime = currentDateTime
      end
    elsif unit_data.occupancy == 'vacant'
      if unit.vacant_start_datetime.nil?
        if unit.occupied_start_datetime.present?
          unit.occupied_prev_start_datetime = unit.occupied_start_datetime
          unit.occupied_start_datetime = nil
        end
        if unit.occupied_end_datetime.present?
          unit.occupied_prev_end_datetime = unit.occupied_end_datetime
          unit.occupied_end_datetime = nil
        end
        unit.vacant_start_datetime = currentDateTime
      else  
        unit.vacant_end_datetime = currentDateTime
      end
    end

    # Set RentReady start/end
    # Reset previous window
    # Store previous RentReady start/end, for previous stats
    if unit_data.rent_ready == false
      if unit.rent_ready_start_datetime.present?
        unit.rent_ready_prev_start_datetime = unit.rent_ready_start_datetime
        unit.rent_ready_start_datetime = nil
      end
      if unit.rent_ready_end_datetime.present?
        unit.rent_ready_prev_end_datetime = unit.rent_ready_end_datetime
        unit.rent_ready_end_datetime = nil
      end
    elsif unit.rent_ready_start_datetime.nil?
      unit.rent_ready_start_datetime = currentDateTime
    else  
      unit.rent_ready_end_datetime = currentDateTime
    end

    # Set Leased start/end
    # Reset previous window
    # Store previous Leased start/end, for previous stats
    if unit_data.lease_status != 'leased'
      if unit.leased_start_datetime.present?
        unit.leased_prev_start_datetime = unit.leased_start_datetime
        unit.leased_start_datetime = nil
      end
      if unit.leased_end_datetime.present?
        unit.leased_prev_end_datetime = unit.leased_end_datetime
        unit.leased_end_datetime = nil
      end
    elsif unit.leased_start_datetime.nil?
      unit.leased_start_datetime = currentDateTime
    else  
      unit.leased_end_datetime = currentDateTime
    end


    # Day Vacant
    if unit.vacant_start_datetime.present? && unit.vacant_end_datetime.present?
      unit.days_vacant = (unit.vacant_end_datetime.to_datetime - unit.vacant_start_datetime.to_datetime).to_i
    else  
      unit.days_vacant = nil
    end

    # Day Vacant (Previous)
    if unit.vacant_prev_start_datetime.present? && unit.vacant_prev_end_datetime.present?
      unit.prev_days_vacant = (unit.vacant_prev_end_datetime.to_datetime - unit.vacant_prev_start_datetime.to_datetime).to_i
    else  
      unit.prev_days_vacant = nil
    end


    # Days Vacant to Rent Ready
    # If Rent Ready start is after Vacant start
    if    unit.vacant_start_datetime.present? && 
          unit.rent_ready_start_datetime.present? && 
          unit.rent_ready_start_datetime >= unit.vacant_start_datetime &&
          unit.rent_ready_start_datetime > unit.data_start_datetime
      unit.days_vacant_to_ready = (unit.rent_ready_start_datetime.to_datetime - unit.vacant_start_datetime.to_datetime).to_i
    # If Rent Ready start < Vacant, and Rent Ready end > Vacant, then Leased came first, set days to zero
    elsif unit.vacant_start_datetime.present? && 
          unit.rent_ready_end_datetime.present? && 
          unit.rent_ready_start_datetime < unit.vacant_start_datetime &&
          unit.rent_ready_end_datetime > unit.vacant_start_datetime
      unit.days_vacant_to_ready = 0
    else  
      unit.days_vacant_to_ready = nil
    end

    # Days Vacant to Rent Ready (Previous)
    # If Rent Ready start is after Vacant start
    if    unit.vacant_prev_start_datetime.present? && 
          unit.rent_ready_prev_start_datetime.present? && 
          unit.rent_ready_prev_start_datetime >= unit.vacant_prev_start_datetime &&
          unit.rent_ready_prev_start_datetime > unit.data_start_datetime
      unit.prev_days_vacant_to_ready = (unit.rent_ready_prev_start_datetime.to_datetime - unit.vacant_prev_start_datetime.to_datetime).to_i
    # If Rent Ready start < Vacant, and Rent Ready end > Vacant, then Leased came first, set days to zero
    elsif unit.vacant_prev_start_datetime.present? && 
          unit.rent_ready_prev_end_datetime.present? && 
          unit.rent_ready_prev_start_datetime < unit.vacant_prev_start_datetime &&
          unit.rent_ready_prev_end_datetime > unit.vacant_prev_start_datetime
      unit.prev_days_vacant_to_ready = 0
    else  
      unit.prev_days_vacant_to_ready = nil
    end


    # Days Rent Ready to Leased
    # If Leased start is after Rent Ready start
    if    unit.rent_ready_start_datetime.present? && 
          unit.leased_start_datetime.present? && 
          unit.leased_start_datetime >= unit.rent_ready_start_datetime &&
          unit.leased_start_datetime > unit.data_start_datetime
      unit.days_ready_to_leased = (unit.leased_start_datetime.to_datetime - unit.rent_ready_start_datetime.to_datetime).to_i
    # If Leased start < Rent Ready, and Leased end > Rent Ready, then Leased came first, set days to zero
    elsif unit.rent_ready_start_datetime.present? && 
          unit.leased_end_datetime.present? && 
          unit.leased_start_datetime < unit.rent_ready_start_datetime &&
          unit.leased_end_datetime > unit.rent_ready_start_datetime
      unit.days_ready_to_leased = 0
    else  
      unit.days_ready_to_leased = nil
    end

    # Days Rent Ready to Leased (Previous)
    # If Leased start is after Rent Ready start
    if    unit.rent_ready_prev_start_datetime.present? && 
          unit.leased_prev_start_datetime.present? && 
          unit.leased_prev_start_datetime >= unit.rent_ready_prev_start_datetime &&
          unit.leased_prev_start_datetime > unit.data_start_datetime
      unit.prev_days_ready_to_leased = (unit.leased_prev_start_datetime.to_datetime - unit.rent_ready_prev_start_datetime.to_datetime).to_i
    # If Leased start < Rent Ready, and Leased end > Rent Ready, then Leased came first, set days to zero
    elsif unit.rent_ready_prev_start_datetime.present? && 
          unit.leased_prev_end_datetime.present? && 
          unit.leased_prev_start_datetime < unit.rent_ready_prev_start_datetime &&
          unit.leased_prev_end_datetime > unit.rent_ready_prev_start_datetime
      unit.prev_days_ready_to_leased = 0
    else  
      unit.prev_days_ready_to_leased = nil
    end


    # Days Rent Ready to Occupied
    # If Leased start is after Rent Ready start
    if    unit.rent_ready_start_datetime.present? && 
          unit.occupied_start_datetime.present? && 
          unit.occupied_start_datetime >= unit.rent_ready_start_datetime &&
          unit.occupied_start_datetime > unit.data_start_datetime
      unit.days_ready_to_occupied = (unit.occupied_start_datetime.to_datetime - unit.rent_ready_start_datetime.to_datetime).to_i
    # If Occupied start < Rent Ready, and Occupied end > Rent Ready, then Leased came first, set days to zero
    elsif unit.rent_ready_start_datetime.present? && 
          unit.occupied_end_datetime.present? && 
          unit.occupied_start_datetime < unit.rent_ready_start_datetime &&
          unit.occupied_end_datetime > unit.rent_ready_start_datetime
      unit.days_ready_to_occupied = 0
    else  
      unit.days_ready_to_occupied = nil
    end

    # Days Rent Ready to Occupied (Previous)
    # If Occupied start is after Rent Ready start
    if    unit.rent_ready_prev_start_datetime.present? && 
          unit.occupied_prev_start_datetime.present? && 
          unit.occupied_prev_start_datetime >= unit.rent_ready_prev_start_datetime &&
          unit.occupied_prev_start_datetime > unit.data_start_datetime
      unit.prev_days_ready_to_occupied = (unit.occupied_prev_start_datetime.to_datetime - unit.rent_ready_prev_start_datetime.to_datetime).to_i
    # If Occupied start < Rent Ready, and Occupied end > Rent Ready, then Leased came first, set days to zero
    elsif unit.rent_ready_prev_start_datetime.present? && 
          unit.occupied_prev_end_datetime.present? && 
          unit.occupied_prev_start_datetime < unit.rent_ready_prev_start_datetime &&
          unit.occupied_prev_end_datetime > unit.rent_ready_prev_start_datetime
      unit.prev_days_ready_to_occupied = 0
    else  
      unit.prev_days_ready_to_occupied = nil
    end

    unit.save
  end

end

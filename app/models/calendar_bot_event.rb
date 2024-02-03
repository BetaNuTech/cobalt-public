# == Schema Information
#
# Table name: calendar_bot_events
#
#  id               :integer          not null, primary key
#  sent             :boolean          default(FALSE)
#  event_date       :date
#  title            :string
#  description      :string
#  background_color :string
#  border_color     :string
#  text_color       :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
class CalendarBotEvent < ActiveRecord::Base
  validates :event_date, presence: true
  validates :title, presence: true
  validates :description, presence: true

end

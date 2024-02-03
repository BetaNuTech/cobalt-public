class CreateCalendarBotEvents < ActiveRecord::Migration
  def change
    create_table :calendar_bot_events do |t|
      t.boolean :sent, default: false, index: true
      t.date :event_date, index: true

      t.string :title
      t.string :description
      t.string :background_color
      t.string :border_color
      t.string :text_color

      t.timestamps null: false
    end
  end
end

# TODO: Remove this hack later (there is already a class for this)
# class Settings < Settingslogic
#     source "#{Rails.root}/config/settings.yml"
#     namespace Rails.env    
# end

# Load the Rails application.
require_relative "application"

# Initialize the Rails application.
Rails.application.initialize!

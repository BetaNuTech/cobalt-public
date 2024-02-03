# require 'carrierwave/orm/activerecord'
# require 'carrierwave/storage/file'
# require 'carrierwave/storage/fog'
# require 'fog/aws'

CarrierWave.configure do |config|

    # config.cache_dir = "#{Rails.root}/tmp/"
    config.fog_provider = 'fog/aws'
    config.fog_credentials = {
        provider:              'AWS',               # required
        aws_access_key_id:     Settings.aws_key,    # required unless using use_iam_profile
        aws_secret_access_key: Settings.aws_secret, # required unless using use_iam_profile
        region:                'us-east-1'         # optional, defaults to 'us-east-1'
    }
    config.fog_directory  = Settings.s3_bucket   # required
    # config.fog_public     = true                 # optional, defaults to true
    config.fog_attributes = { 'Cache-Control' => "public, max-age=#{1.year.to_i}" }                  # optional, defaults to {}
    config.storage = :fog

end

S3FileField.config do |c|
  c.access_key_id = Settings.aws_key
  c.secret_access_key = Settings.aws_secret
  c.bucket = Settings.s3_bucket
  # c.acl = "public-read"
  # c.expiration = 10.hours.from_now.utc.iso8601
  # c.max_file_size = 10.megabytes
  # c.conditions = []
  c.key_starts_with = 'uploads/'
  # c.ssl = true # if true, force SSL connection
end

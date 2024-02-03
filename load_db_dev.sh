echo "Loading Cobalt Dev database"
[ ! -f latest.dump ] && heroku pg:backups:download --app cobalt-dev
/Applications/Postgres.app/Contents/Versions/15/bin/dropdb cobalt_development
/Applications/Postgres.app/Contents/Versions/15/bin/createdb cobalt_development -O $USER
/Applications/Postgres.app/Contents/Versions/15/bin/pg_restore --verbose --clean --no-acl --no-owner -U $USER -d cobalt_development latest.dump
rake db:migrate
rm latest.dump


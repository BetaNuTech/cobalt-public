
require 'active_record/fixtures'
 
namespace :deploy do
  desc "Deploy production to heroku"
  
  task :dev do     
    root = Rake.application.original_dir  
  
    command = "cd #{root} &&
      date_str=$(date +%y%m%d%H%M) &&
      tag=\"dev-$date_str\" &&
      echo \"  - Creating tag $tag\" &&
      git tag -f $tag &&
      git push --tags -f &&
      git push heroku-dev dev:master && 
      heroku run rake db:migrate -a cobalt-dev"
     
    execute_command(command)
  end
  
  task :production do     
    root = Rake.application.original_dir  

    command = "cd #{root} &&
        date_str=$(date +%y%m%d%H%M) &&
        tag=\"prod-$date_str\" &&
        echo \"  - Creating tag $tag\" &&
        git tag -f $tag &&
        git push --tags -f &&
        git push heroku-production production:master && 
        heroku run rake db:migrate -a cobalt-production"
     
    execute_command(command)
  end
end

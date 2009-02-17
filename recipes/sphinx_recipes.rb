namespace :sphinx do
  desc "Starts the sphinx daemon"
  task :start, :roles => [:app] do
    rails_env = fetch(:rails_env, "production")
    
    run "cd #{current_path}; rake ts:start RAILS_ENV=#{rails_env}"
  end
  
  desc "Stops the sphinx daemon"
  task :stop, :roles => [:app] do
    rails_env = fetch(:rails_env, "production")
    run "cd #{current_path}; rake ts:stop RAILS_ENV=#{rails_env}"
  end
  
  desc "Restarts the sphinx daemon"
  task :restart, :roles => [:app] do
    sphinx.stop
    sphinx.start
  end
  
  desc "Index the sphinx"
  task :index, :roles => [:app] do
    rails_env = fetch(:rails_env, "production")
    run "cd #{current_path}; rake ts:index RAILS_ENV=#{rails_env}"
  end
end

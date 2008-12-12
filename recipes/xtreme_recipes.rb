namespace :deploy do
  namespace :web do
    desc "Serve up a custom maintenance page."
    task :disable, :roles => :web do
      require 'erb'
      on_rollback { run "rm #{shared_path}/system/maintenance.html" }
      
      reason      = ENV['REASON']
      deadline    = ENV['UNTIL']
      
      template = File.read("app/views/home/maintenance.html.erb")
      page = ERB.new(template).result(binding)


      puts "  * REASON: #{reason} *"
      puts "  * DEADLINE: #{deadline} *"
      
      put page, "#{shared_path}/system/maintenance.html", 
                :mode => 0644
    end
  end
  
  namespace :mongrel do
    [ :stop, :start, :restart ].each do |t|
      desc "#{t.to_s.capitalize} the mongrel appserver"
      task t, :roles => :app do
        invoke_command "mongrel_rails cluster::#{t.to_s} -C #{mongrel_conf}", :via => run_method
      end
    end
  end
  
  desc "Custom restart task for mongrel cluster"
  task :restart, :roles => :app, :except => { :no_release => true } do
    deploy.mongrel.restart
  end
  
  desc "Custom start task for mongrel cluster"
  task :start, :roles => :app do
    deploy.mongrel.start
  end
  
  desc "Custom stop task for mongrel cluster"
  task :stop, :roles => :app do
    deploy.mongrel.stop
  end
  
end

namespace :ferret do
  desc "Start ferret server"
  task :start, :roles => :app do 
    puts " *** GLÖM INTE ATT STARTA FERRET!"
    #run "cd #{current_path}; ./script/ferret_server -e production start"
  end
  
  desc "foo"
  task :stop, :roles => :app do
    #run "cd #{current_path}; echo $PWD; ./script/ferret_server -e production stop"
  end
end


desc "Open script/console on the remote machine"
task :console, :roles => :app do
  input = ''
  cmd = "cd #{current_path} && ./script/console #{ENV['RAILS_ENV']}"
  run cmd, :once => true do |channel, stream, data|
    next if data.chomp == input.chomp || data.chomp == ''
    print data
    channel.send_data(input = $stdin.gets) if data =~ /^(>|\?)>/
  end
end

desc "Echo the remote server PATH"
task :path, :roles => :app do
  run "echo $PATH"
  run "which ruby"
end

desc "Watch multiple log files at the same time"
task :tail_log, :roles => :app do
  stream "tail -f #{shared_path}/log/production.log"
end

desc "Moves the config files and links the production.log file correctly"
task :update_config, :roles => [:app] do
  run "cp -Rf #{shared_path}/config/* #{release_path}/config/"
end
after "deploy:update_code", :update_config

namespace :deploy do
  desc <<-DESC
    Run the migrate rake task. By default, it runs this in most recently \
    deployed version of the app. However, you can specify a different release \
    via the migrate_target variable, which must be one of :latest (for the \
    default behavior), or :current (for the release indicated by the \
    `current' symlink). Strings will work for those values instead of symbols, \
    too. You can also specify additional environment variables to pass to rake \
    via the migrate_env variable. Finally, you can specify the full path to the \
    rake executable by setting the rake variable. The defaults are:
  
      set :rake,           "rake"
      set :rails_env,      "production"
      set :migrate_env,    ""
      set :migrate_target, :latest
  DESC
  task :migrate, :roles => :app, :only => { :primary => true } do
    rake = fetch(:rake, "rake")
    rails_env = fetch(:rails_env, "production")
    migrate_env = fetch(:migrate_env, "")
    migrate_target = fetch(:migrate_target, :latest)
  
    directory = case migrate_target.to_sym
      when :current then current_path
      when :latest  then current_release
      else raise ArgumentError, "unknown migration target #{migrate_target.inspect}"
      end
  
    run "cd #{directory}; #{rake} RAILS_ENV=#{rails_env} #{migrate_env} db:migrate"
  end
end




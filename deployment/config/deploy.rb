require 'rubygems'
require 'aws-sdk'

sdb = AWS::SimpleDB.new(
  :access_key_id => "AKIAIA6J23Q7RZ4GKXKA",
  :secret_access_key => "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")
  
set :domain do
  item = sdb.domains["test"].items['parameters']
  puts item.attributes['params'].values[0]
end

set :user,             "ec2-user"
set :application,      "rails"
set :use_sudo,         false
set :deploy_to,        "/var/www/#{application}"
set :artifact_bucket,  "stelligentlabs"
set :artifact,         "devopsinthecloud.tar.gz"
set :artifact_url,     "https://s3.amazonaws.com/#{artifact_bucket}/#{artifact}"
set :ssh_options,      {:forward_agent => true}

role :app, domain
role :web, domain
role :db,  domain, :primary => true

set :deploy_via, :remote_cache

after "deploy:setup", "deploy:deploy"
after "deploy:deploy", "deploy:bundle_install"
after "deploy:bundle_install", "deploy:db_migrate"
after "deploy:db_migrate", "deploy:restart"

namespace :deploy do
  task :setup do
    run "sudo rm -rf #{deploy_to}"
    run "sudo mkdir #{deploy_to}"
    run "sudo chown -R #{user}:#{user} #{deploy_to}"
  end
  
  task :deploy do
    run "cd #{deploy_to} && sudo wget #{artifact_url}"
    run "cd #{deploy_to} && sudo tar -zxf #{artifact}"
    run "cd #{deploy_to} && sudo rm #{artifact}"
  end
  
  task :bundle_install do
    run "cd #{deploy_to} && bundle install"
  end
  
  task :db_migrate do
    run "cd #{deploy_to} && sudo rake db:migrate"
  end
  
  task :start, :roles => :app do
    run "sudo service httpd start"
  end

  task :stop, :roles => :app do
    run "sudo service httpd stop"
  end

  desc "Restart Application"
  task :restart, :roles => :app do
    run "sudo service httpd restart"
  end
end
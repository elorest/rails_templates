# http://guides.rubyonrails.org/rails_application_templates.html#gem-args
# generate(:scaffold, "person name:string")
# route "root to: 'people#index'"
# rake("db:migrate")
#
gem 'devise'
gem 'petergate'
gem 'petergate_api'
gem 'pry-rails'
gem 'annotate'
gem 'slim-rails'
gem 'bootstrap-sass'
gem 'font-awesome-sass'

gem_group :development do
  gem 'web-console', '~> 2.0'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'capistrano'
  gem 'capistrano-passenger'
  gem 'capistrano-bundler'
  gem 'capistrano-rails'
  gem 'capistrano-rails-console'
  gem 'capistrano-rvm'
end

gem_group :development, :test do
  gem 'minitest'
  gem 'minitest-rails'
end

after_bundle do
  run "rails g devise:install"
  run "rails g devise User"
  run "rails g petergate:install"
  run "rails g petergate_api:install"
  run "mv app/assets/stylesheets/application.css app/assets/stylesheets/application.sass"
  run "rails generate devise:views"
  run "gem install html2slim"
  run "for file in app/views/devise/**/*.erb; do erb2slim $file ${file%erb}slim && rm $file; done" 
  run "mkdir config/deploy"

  git :init
  git add: "."
  git commit: %Q{ -m 'Initial commit' }
end

application %Q(
  config.generators do |g|
    g.test_framework :minitest, spec: true, fixture: true
    g.helper false
    g.view_specs false
  end
)

run "cp -rf #{File.join(File.expand_path(File.dirname(__FILE__)), "lib/templates")} lib/"

######################### config/environments/development ##########################
environment 'config.action_mailer.default_url_options = {host: "http://yourwebsite.example.com"}', env: 'development'
######################### app/assets/stylesheets/application.scss  ##########################
file 'app/assets/stylesheets/application.css', <<-CODE
// "bootstrap-sprockets" must be imported before "bootstrap" and "bootstrap/variables"
@import bootstrap-sprockets
@import bootstrap
@import font-awesome-sprockets
@import font-awesome
CODE

######################### app/assets/javascripts/application.js ##########################
file 'app/assets/javascripts/application.js', <<-CODE
//= require jquery
//= require jquery_ujs
//= require turbolinks
//= require_tree .
//= require bootstrap-sprockets
CODE

file 'config/deploy.rb', <<-CODE
set :application, 'example'
set :repo_url, 'git@git.example.git'

set :branch, :master 

set :deploy_to, '~/www/example.com'
set :scm, :git

set :format, :pretty
set :linked_dirs, %w{log tmp vendor/bundle public/system public/uploads}
# set :log_level, :info
set :log_level, :info
set :rails_env, "production"
# set :pty, true

# set :linked_files, %w{config/database.yml}

# set :default_env, { path: "/opt/ruby/bin:$PATH" }
# set :keep_releases, 5

namespace :deploy do
  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      # Your restart mechanism here, for example:
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end
  after :publishing, "deploy:restart"
  after :finishing, 'deploy:cleanup'
end

namespace :db do
  task :full_reset do
    on roles(:app) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :bundle, "exec rake db:full_reset"
        end
      end
    end
  end
end
CODE

file 'config/deploy/production.rb', <<-CODE
set :stage, :production
set :branch, ENV["branch"] || "master"
set :env, "production" 

# Simple Role Syntax
# ==================
# Supports bulk-adding hosts to roles, the primary
# server in each group is considered to be the first
# unless any hosts have the primary property set.
domains = %w{example@changme.com}
role :app, domains 
role :web, domains 
role :db,  domains

# Extended Server Syntax
# ======================
# This can be used to drop a more detailed server
# definition into the server list. The second argument
# something that quacks like a hash can be used to set
# extended properties on the server.
server domains.first, user: 'deploy', roles: %w{web app}, my_property: :my_value

# you can set custom ssh options
# it's possible to pass any option but you need to keep in mind that net/ssh understand limited list of options
# you can see them in [net/ssh documentation](http://net-ssh.github.io/net-ssh/classes/Net/SSH.html#method-c-start)
# set it globally
#  set :ssh_options, {
#    keys: %w(/home/rlisowski/.ssh/id_rsa),
#    forward_agent: false,
#    auth_methods: %w(password)
#  }
# and/or per server
# server 'example.com',
#   user: 'user_name',
#   roles: %w{web app},
#   ssh_options: {
#     user: 'user_name', # overrides user setting above
#     keys: %w(/home/user_name/.ssh/id_rsa),
#     forward_agent: false,
#     auth_methods: %w(publickey password)
#     # password: 'please use keys'
#   }
# setting per server overrides global ssh_options

# fetch(:default_env).merge!(rails_env: :production)
CODE

file 'config/deploy/staging.rb', <<-CODE
set :stage, :staging
set :branch, ENV["branch"] || "master"
set :rails_env, "production"

# Simple Role Syntax
# ==================
# Supports bulk-adding hosts to roles, the primary
# server in each group is considered to be the first
# unless any hosts have the primary property set.
# if (copy_id_present = `which ssh-copy-id`).size < 1 || copy_id_present.include?("not found")
#   `brew install ssh-copy-id`
# end

domains = %w{example@changme.com}
role :app, domains 
role :web, domains 
role :db,  domains

# Extended Server Syntax
# ======================
# This can be used to drop a more detailed server
# definition into the server list. The second argument
# something that quacks like a hash can be used to set
# extended properties on the server.
server domains.first, user: 'deploy', roles: %w{web app}, my_property: :my_value

# you can set custom ssh options
# it's possible to pass any option but you need to keep in mind that net/ssh understand limited list of options
# you can see them in [net/ssh documentation](http://net-ssh.github.io/net-ssh/classes/Net/SSH.html#method-c-start)
# set it globally
#  set :ssh_options, {
#    keys: %w(/home/rlisowski/.ssh/id_rsa),
#    forward_agent: false,
#    auth_methods: %w(password)
#  }
# and/or per server
# server 'example.com',
#   user: 'user_name',
#   roles: %w{web app},
#   ssh_options: {
#     user: 'user_name', # overrides user setting above
#     keys: %w(/home/user_name/.ssh/id_rsa),
#     forward_agent: false,
#     auth_methods: %w(publickey password)
#     # password: 'please use keys'
#   }
# setting per server overrides global ssh_options

# fetch(:default_env).merge!(rails_env: :staging)
CODE

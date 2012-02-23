# REQUIREMENTS
# RVM, Rails, Thor

# USAGE
# Place the templates folder in the same folder that all your rails apps are in or change the path in the command below

# $ rails new appname -m templates/rails31_noauth.rb
# $ cd appname
# $ gem install bundler
# $ bundle install


run "echo 'rvm use 1.9.2@#{app_name} --create' > .rvmrc"


#gem 'inherited_resources', '1.2.1'
#gem 'compass', "~> 0.11.5"
#gem 'devise'
#gem 'omniauth'
#gem "cancan", "1.6.5"

inject_into_file 'Gemfile', :after => "gem 'uglifier', '>= 1.0.3'" do
  <<-eos
  
   gem "compass", "~> 0.12.alpha.0"
      
  eos
end

inject_into_file 'Gemfile', :after => "gem 'sqlite3'" do
  <<-eos
  
group :development do
  gem "mongrel", "~> 1.2.0.pre2"
end
      
  eos
end

inside app_name do
  run 'bundle install'
end

#generate 'backbonejs:install'


#Compass
screen_path = File.join(File.dirname(__FILE__), 'files','temp_screen.scss')
base_path = File.join(File.dirname(__FILE__), 'files','temp_base.scss')
copy_file(screen_path, "app/assets/stylesheets/screen.css.scss")
copy_file(base_path, "app/assets/stylesheets/partials/_base.css.scss")


#FIX COMPASS on HEROKU
# compass_config_path = File.join(File.dirname(__FILE__), 'files','compass_config.rb')
# copy_file(compass_config_path, "config/compass.rb")
# compass_initalizer_path = File.join(File.dirname(__FILE__), 'files','compass_initializer.rb')
# copy_file(compass_initializer_path, "config/initializers/compass.rb")

# HOME
generate("controller home index") #This wants mongrel for some reason
route("root :to => 'home#index'") #Inserted at the top of the routes.rb file

# DASHBOARD
generate("controller dashboard")
inject_into_file "app/controllers/dashboard_controller.rb", :after => "class DashboardController < ApplicationController"  do
  <<-RUBY
  
  before_filter :authenticate_user!
  
  def show
  end
  
  RUBY
end
route('match "/dashboard", :to => "dashboard#show", :as => :dashboard')  #Inserted at the top of the routes.rb file
create_file "app/views/dashboard/show.html.erb" do
    "<p>Find me in app/views/dashboard/show.html.erb</p>"
end



# clean up rails defaults
remove_file 'public/index.html'
remove_file 'public/images/rails.png'
run 'cp config/database.yml config/database.example'
run "echo 'config/database.yml' >> .gitignore"

#JAVASCRIPT FLASH NOTICES
inject_into_file 'app/assets/javascripts/application.js', :after => "//= require_tree ." do
  <<-eos
  
//DOM is Ready
$(function(){
  
  //PUSHDOWN MESSAGES
  if ($(".flashy").length) {
     $("div.close_me").live("click", function(){
       $(this).hide();
       $("div#messages").hide();
     });
     $("div#messages").slideDown();
     $("div#messages").delay(5000).slideUp();
  }
});
      
  eos
end

#Application.html.erb DOM stuff
temp_application_html_path = File.join(File.dirname(__FILE__), 'files','noauth_application.html.erb')
remove_file("app/views/layouts/application.html.erb")
copy_file(temp_application_html_path, "app/views/layouts/application.html.erb")



#FIX RAKE PROBLEM on HEROKU
inject_into_file 'Rakefile', "require 'rake/dsl_definition'", :before => "require 'rake'"


#rake "db:migrate"

run "say Your App is Ready"

say <<-eos
  ============================================================================
  Your new Rails application is ready to go.
  
  Don't forget to scroll up for important messages from installed generators.
  
  Next: 
  
  1. cd #{app_name}
  2. Accept the .rvmrc file
  3. run $ gem install bundler
  4. run $ bundle install
  
eos
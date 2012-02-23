# REQUIREMENTS
# RVM, Rails, Thor

# USAGE
# Place the templates folder in the same folder that all your rails apps are in or change the path in the command below

# $ rvm 1.9.2@rails31
# $ rails new appname -m templates/rails31.rb
# $ cd appname
# $ gem install bundler
# $ bundle install
# $ createdb appname_development

#This template allows multiple omniauth accounts for each user

run "echo 'rvm use 1.9.2@#{app_name} --create' > .rvmrc"


gem "pg"
gem "thin"
gem 'backbonejs-rails'
gem 'inherited_resources', '1.2.1'
gem 'devise'
gem 'omniauth'
gem 'omniauth-twitter'
gem 'omniauth-facebook'
gem "cancan"

inject_into_file 'Gemfile', :after => "gem 'uglifier', '>= 1.0.3'" do
  <<-eos
  
   gem "compass", "~> 0.12.alpha.0"
      
  eos
end

inside app_name do
  run 'bundle install'
end


#CSS includes
remove_file("app/assets/stylesheets/application.css")
application_path = File.join(File.dirname(__FILE__), 'files','temp_application.css')
copy_file(application_path, "app/assets/stylesheets/application.css")


#Compass
screen_path = File.join(File.dirname(__FILE__), 'files','temp_screen.scss')
base_path = File.join(File.dirname(__FILE__), 'files','temp_base.scss')

#Twitter Bootstrap
bootstrap_path = File.join(File.dirname(__FILE__), 'files','bootstrap/bootstrap.scss')
forms_path = File.join(File.dirname(__FILE__), 'files','bootstrap/forms.scss')
mixins_path = File.join(File.dirname(__FILE__), 'files','bootstrap/mixins.scss')
patterns_path = File.join(File.dirname(__FILE__), 'files','bootstrap/patterns.scss')
reset_path = File.join(File.dirname(__FILE__), 'files','bootstrap/reset.scss')
scaffolding_path = File.join(File.dirname(__FILE__), 'files','bootstrap/scaffolding.scss')
tables_path = File.join(File.dirname(__FILE__), 'files','bootstrap/tables.scss')
type_path = File.join(File.dirname(__FILE__), 'files','bootstrap/type.scss')
variables_path = File.join(File.dirname(__FILE__), 'files','bootstrap/variables.scss')
copy_file(screen_path, "app/assets/stylesheets/screen.css.scss")
copy_file(base_path, "app/assets/stylesheets/partials/_base.css.scss")
copy_file(bootstrap_path, "app/assets/stylesheets/bootstrap/bootstrap.scss")
copy_file(forms_path, "app/assets/stylesheets/bootstrap/forms.scss")
copy_file(mixins_path, "app/assets/stylesheets/bootstrap/mixins.scss")
copy_file(patterns_path, "app/assets/stylesheets/bootstrap/patterns.scss")
copy_file(reset_path, "app/assets/stylesheets/bootstrap/reset.scss")
copy_file(scaffolding_path, "app/assets/stylesheets/bootstrap/scaffolding.scss")
copy_file(tables_path, "app/assets/stylesheets/bootstrap/tables.scss")
copy_file(type_path, "app/assets/stylesheets/bootstrap/type.scss")
copy_file(variables_path, "app/assets/stylesheets/bootstrap/variables.scss")

# [apg] TODO - figure out how to do this
# Dir["config/examples/*"].each do |source|
#    destination = "config/#{File.basename(source)}"
#    if File.exist?(destination)
#      puts "Skipping #{destination} because it already exists"
#    else
#      puts "Generating #{destination}"
#      FileUtils.cp(source, destination)
#    end
# end

#javascript
js_path = File.join(File.dirname(__FILE__), 'files','bootstrap-dropdown.js')
copy_file(js_path, "app/assets/javascripts/bootstrap-dropdown.js")
js_path = File.join(File.dirname(__FILE__), 'files','spin.min.js')
copy_file(js_path, "app/assets/javascripts/spin.min.js")

remove_file("app/assets/stylesheets/application.js")
js_path = File.join(File.dirname(__FILE__), 'files','application.js')
copy_file(js_path, "app/assets/javascripts/application.js")

#images
image_path = File.join(File.dirname(__FILE__), 'files','images/298-circlex-white.png')
copy_file(image_path, "app/assets/images/298-circlex-white.png")
image_path = File.join(File.dirname(__FILE__), 'files','images/298-circlex.png')
copy_file(image_path, "app/assets/images/298-circlex.png")
image_path = File.join(File.dirname(__FILE__), 'files','images/circles.png')
copy_file(image_path, "app/assets/images/circles.png")

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
    '<%= title "App Name | Dashboard" %> <p>Find me in app/views/dashboard/show.html.erb</p>'
end

inject_into_file 'app/controllers/home_controller.rb', :after => "def index" do
  <<-eos
  
  respond_to do |format|
    format.html   { redirect_to dashboard_path if user_signed_in? }
  end

  eos
end

# CANCAN setup
generate "cancan:ability"

inject_into_file 'app/controllers/application_controller.rb', :after => "protect_from_forgery" do
  <<-eos
  
rescue_from CanCan::AccessDenied do |exception|
  redirect_to root_url, :alert => exception.message
end

  eos
end

# title helper
inject_into_file 'app/helpers/application_helper.rb', :after => "module ApplicationHelper" do
  <<-RUBY
  
  def title(page_title)
    content_for(:title) { page_title }
  end

  RUBY
end

# DEVISE setup
generate "devise:install"
generate "devise User"
generate "devise:views"
inject_into_file Dir["db/migrate/*_devise_create_users.rb"].first, "\nt.token_authenticatable", :after => "t.trackable"

create_file "app/controllers/registrations_controller.rb", "# Override Devise Registrations"
inject_into_file 'app/controllers/registrations_controller.rb', :after => "# Override Devise Registrations" do
  <<-eos

class RegistrationsController < Devise::RegistrationsController
  def create
    #This is a security measure to ensure that someone does not try to force their role to be "admin" at registration
    if params[:user].key?(:role) == true
      redirect_to root_url
    end
    
    #Sets default role for a new user to be "user"
    params[:user][:role] = "user"
    
    #Automatically sets password_confirmation to the value of password.
    params[:user][:password_confirmation] = params[:user][:password]
    super
  end
end

  eos
end


# ADD custom UPDATE method to Users controller
create_file "app/controllers/users_controller.rb", "# Devise Users Controller"
inject_into_file 'app/controllers/users_controller.rb', :after => "# Devise Users Controller" do
  <<-eos
  
class UsersController < InheritedResources::Base
  
  before_filter :authenticate_user!
  load_and_authorize_resource
  
  #actions :all, :except => [:index, :show]
  actions :index, :new, :edit, :create, :update, :destroy, :show
  # respond_to :html, :xml, :json
  # respond_to :js, :only => :create
  # respond_to :iphone, :except => [ :edit, :update ]
  respond_to :html, :json
  
  #This allows the user to update their profile without changing their password
  def update
    params[:user].delete(:password) if params[:user][:password].blank?
    params[:user].delete(:password_confirmation) if params[:user][:password].blank? and params[:user][:password_confirmation].blank?
    
    update! do |success, failure|
      success.html{ redirect_to dashboard_path }
      success.json  { render :json => @user }
      failure.html{ redirect_to dashboard_path }
      failure.json  { render :json => @user, :status => 406}
    end
  end
end

  eos
end

#create authentications controller
temp_authentications_controller_path = File.join(File.dirname(__FILE__), 'files','authentications_controller.rb')
# remove_file("app/controllers/authentications_controller.rb")
copy_file(temp_authentications_controller_path, "app/controllers/authentications_controller.rb")

# Add :token_authenticatable to User Model
inject_into_file "app/models/user.rb", " :token_authenticatable,", :after => "devise :database_authenticatable, :registerable,"
inject_into_file "app/models/user.rb", ", :first_name, :last_name", :after => "attr_accessible :email, :password, :password_confirmation, :remember_me"

inject_into_file 'app/models/user.rb', :after => ":first_name, :last_name" do
  <<-RUBY
    
  
  #Checks to see if the email is blank in the API return
  def self.apply_omniauth(omniauth)
    if user = User.find_by_email(omniauth['user_info']['email'])
      user
    else
      user = User.create!(
        :email => omniauth['user_info']['email'],
        :password => Devise.friendly_token[0,20],
        :last_name => omniauth['user_info']['last_name'],
        :first_name => omniauth['user_info']['first_name']
        )
        
      user.authentications.build(:provider => omniauth['provider'], :uid => omniauth['uid'])
      user
    end
  end
    
  RUBY
end

# Add profile fields to Users model with a migration
generate("migration add_fields_to_users first_name:string last_name:string role:string")
generate("model authentication user_id:integer uid:string provider:string")

#Create Registration and User views
registrations_edit_path = File.join(File.dirname(__FILE__), 'files','registrations_edit.html.erb')
registrations_new_path = File.join(File.dirname(__FILE__), 'files','devise_registrations_new.html.erb')
sessions_new_path = File.join(File.dirname(__FILE__), 'files','devise_sessions_new.html.erb')
users_edit_path = File.join(File.dirname(__FILE__), 'files','users_edit.html.erb')
users_form_path = File.join(File.dirname(__FILE__), 'files','users_form.html.erb')
copy_file(registrations_edit_path, "app/views/registrations/edit.html.erb")
copy_file(registrations_new_path, "app/views/registrations/new.html.erb")
remove_file("app/views/devise/sessions/new.html.erb")
copy_file(sessions_new_path, "app/views/devise/sessions/new.html.erb")
copy_file(users_edit_path, "app/views/users/edit.html.erb")
copy_file(users_form_path, "app/views/users/_form.html.erb")

#Copy CanCan ability.rb
cancan_ability_path = File.join(File.dirname(__FILE__), 'files','cancan_ability.rb')
remove_file("app/models/ability.rb")
copy_file(cancan_ability_path, "app/models/ability.rb")

#Procfile
procfile_path = File.join(File.dirname(__FILE__), 'files','Procfile')
copy_file(procfile_path, "Procfile")

# Create Postgres database.yml file
temp_database_path = File.join(File.dirname(__FILE__), 'files','database.yml')
remove_file("config/database.yml")
copy_file(temp_database_path, "config/database.yml")


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
     $(".close_me").live("click", function(){
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
temp_application_html_path = File.join(File.dirname(__FILE__), 'files','rails31_application.html.erb')
remove_file("app/views/layouts/application.html.erb")
copy_file(temp_application_html_path, "app/views/layouts/application.html.erb")



#FIX RAKE PROBLEM on HEROKU
inject_into_file 'Rakefile', "require 'rake/dsl_definition'", :before => "require 'rake'"


#INITIALIZERS

#Creates a file in the /config/initializers directory
initializer("app_keys.rb") do
  <<-RUBY
    # Examples:
    # FACEBOOK_APP_ID = ENV["FACEBOOK_APP_ID"] || "XXXXXXXXXXXX"
    # FACEBOOK_APP_SECRET = ENV["FACEBOOK_APP_SECRET"] || "XXXXXXXXXXXXXX"
    # HOST_URL = Rails.env.production? ? "gotcup.com" : "localhost:3000"

    FACEBOOK_APP_ID = "PLEASEFIXME"
    FACEBOOK_APP_SECRET = "PLEASEFIXME"
    TWITTER_KEY = "PLEASEFIXME"
    TWITTER_SECRET = "PLEASEFIXME"
  RUBY
end

initializer("omniauth.rb") do
  <<-RUBY
  
  Rails.application.config.middleware.use OmniAuth::Builder do
   # provider :facebook, 'APP_ID', 'APP_SECRET'
   provider :twitter, TWITTER_KEY, TWITTER_SECRET
   #use OmniAuth::Strategies::Twitter, TWITTER_KEY, TWITTER_SECRET # ENV['CONSUMER_KEY'], ENV['CONSUMER_SECRET']
   provider :facebook, FACEBOOK_APP_ID, FACEBOOK_APP_SECRET, :iframe => true, :scope => 'email, user_about_me,
                   user_activities,user_birthday,user_education_history,
                   user_likes, user_location,
                   publish_stream, friends_about_me' #, friends_birthday'
  end

  
  RUBY
end

inject_into_file 'config/initializers/devise.rb', :after => "# ==> OmniAuth" do
  <<-eos
                  
  #Token Authenitcation
  config.token_authentication_key = :auth_token

  eos
end

# ROUTES.rb
inject_into_file "config/routes.rb", ', :controllers => { :registrations => "registrations"}', :after => "devise_for :users"

inject_into_file 'config/routes.rb', :before => 'get "home/index"' do
  <<-eos
  
  devise_scope :user do
   #match '/login' => 'devise/sessions#new'
   match '/logout' => 'devise/sessions#destroy'
   match '/users/sign_out' => 'devise/sessions#destroy'
  end
  
  resources :users

  eos
end

rake "db:migrate"

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
  5. run $ createdb appname_development
  5. update database.yml
  
eos
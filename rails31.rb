# REQUIREMENTS
# RVM, Rails, Thor

# USAGE
# Place the templates folder in the same folder that all your rails apps are in or change the path in the command below

# $ rails new appname -m templates/rails31.rb
# $ cd appname
# $ gem install bundler
# $ bundle install


run "echo 'rvm use 1.9.2@#{app_name} --create' > .rvmrc"


#gem 'jquery-rails'
#gem 'backbonejs-rails', "~> 0.0.3"
gem 'inherited_resources', '1.2.1'
#gem 'compass', "~> 0.11.5"
gem 'devise'
gem 'omniauth'
gem "cancan", "1.6.5"

inject_into_file 'Gemfile', :after => "gem 'uglifier'" do
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

create_file "app/controllers/omniauth_callbacks_controller.rb", "# Devise Omniauth Callbacks"
inject_into_file 'app/controllers/omniauth_callbacks_controller.rb', :after => "# Devise Omniauth Callbacks" do
  <<-eos

class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def facebook
    @user = User.find_for_facebook_oauth(env["omniauth.auth"], current_user)

    if @user.persisted?
      flash[:notice] = I18n.t "devise.omniauth_callbacks.success", :kind => "Facebook"
      sign_in_and_redirect @user, :event => :authentication
    else
      session["devise.facebook_data"] = env["omniauth.auth"]
      redirect_to new_user_registration_url
    end
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

# Add :OMNIAUTHABLE to User Model
inject_into_file "app/models/user.rb", " :omniauthable, :token_authenticatable,", :after => "devise :database_authenticatable, :registerable,"
inject_into_file "app/models/user.rb", ", :first_name, :last_name, :uid, :access_token, :provider", :after => "attr_accessible :email, :password, :password_confirmation, :remember_me"

inject_into_file 'app/models/user.rb', :after => ":access_token, :provider" do
  <<-eos
    
    
    def self.find_for_facebook_oauth(access_token, signed_in_resource=nil)
      #raise access_token.to_yaml

      data = access_token['extra']['user_hash']
      if user = User.find_by_email(data["email"])
        user
      else # Create a user with a stub password. 
        User.create!(:email => data["email"], 
            :password => Devise.friendly_token[0,20],
            :first_name => access_token["user_info"]["first_name"],
            :last_name => access_token["user_info"]["last_name"],
            :uid => access_token["uid"],
            :access_token => access_token["credentials"]["token"],
            :provider => access_token["provider"]) 
      end
    end
    
  eos
end

# Add Profile fields to Users model with a migration
generate("migration add_fields_to_users first_name:string last_name:string role:string uid:string access_token:string provider:string")

#Create Registration and User views
registrations_edit_path = File.join(File.dirname(__FILE__), 'files','registrations_edit.html.erb')
registrations_new_path = File.join(File.dirname(__FILE__), 'files','registrations_new.html.erb')
users_edit_path = File.join(File.dirname(__FILE__), 'files','users_edit.html.erb')
users_form_path = File.join(File.dirname(__FILE__), 'files','users_form.html.erb')
copy_file(registrations_edit_path, "app/views/registrations/edit.html.erb")
copy_file(registrations_new_path, "app/views/registrations/new.html.erb")
copy_file(users_edit_path, "app/views/users/edit.html.erb")
copy_file(users_form_path, "app/views/users/_form.html.erb")

#Copy CanCan ability.rb
cancan_ability_path = File.join(File.dirname(__FILE__), 'files','cancan_ability.rb')
remove_file("app/models/ability.rb")
copy_file(cancan_ability_path, "app/models/ability.rb")



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
  RUBY
end

inject_into_file 'config/initializers/devise.rb', :after => "# ==> OmniAuth" do
  <<-eos
  
  config.omniauth :facebook, FACEBOOK_APP_ID, FACEBOOK_APP_SECRET, :iframe => true, :scope => 'email, user_about_me,user_activities,user_birthday,user_education_history,
                  user_events,user_groups,user_hometown,user_interests,user_likes, user_location,
                  publish_stream, offline_access,
                  friends_about_me, friends_interests, friends_likes'
                  
  #Token Authenitcation
  config.token_authentication_key = :auth_token

  eos
end

# ROUTES.rb
inject_into_file "config/routes.rb", ', :controllers => { :omniauth_callbacks => "omniauth_callbacks", :registrations => "registrations"}', :after => "devise_for :users"

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
  
eos
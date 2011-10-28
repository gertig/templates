class AuthenticationsController < InheritedResources::Base
  respond_to :html, :json, :js
  actions :create, :destroy
  belongs_to :user
  
  def passthru
    render :file => "#{Rails.root}/public/404.html", :status => 404, :layout => false
  end
  
  def create
    omniauthhash = request.env["omniauth.auth"]
    
    # raise omniauthhash.to_yaml
    
    authentication = Authentication.find_by_provider_and_uid(omniauthhash['provider'], omniauthhash['uid'])
     
    if authentication
      # puts "This means the USER has already connected this account before."
      flash[:notice] = "Connection Successful"
      sign_in_and_redirect(:user, authentication.user) #Omniauth method
    elsif current_user 
      # puts "Current_User is logged in and attempting to connect an OAuth account"
      current_user.authentications.create!(:provider => omniauthhash['provider'], :uid => omniauthhash['uid'])
      
      if omniauthhash['provider'] == "twitter"
        current_user.update_attributes(:twitter_access_token => omniauthhash["credentials"]["token"], :twitter_access_secret => omniauthhash["credentials"]["secret"])
        current_user.fill_profile
      end
      
      flash[:notice] = "Connection Successful."
      redirect_to root_url
    else
      # puts "New User or User has not connected FB before"
      @user = User.apply_omniauth(omniauthhash) #Found in the user model
      if @user.persisted?
        flash[:notice] = "Signed in successfully."
        sign_in_and_redirect @user, :event => :authentication #Omniauth method
      else
        session["devise.facebook_data"] = omniauthhash #request.env["omniauth.auth"]
        # session[:omniauthhash] = omniauthhash.except('extra') #This saves the hash to a session cookie without the 'extra' piece of the API return
        redirect_to new_user_registration_url
      end
    end
    
  end
  
  def destroy
    @authentication = current_user.authentications.find(params[:id]) #Authentication.find(params[:id])
    @authentication.destroy
    flash[:notice] = "Successfully destroyed authentication."
    redirect_to root_url
  end
  
end

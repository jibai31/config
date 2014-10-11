### Overview
We'll use OmniAuth, a Rack framework for multiple-provider authentication. It will allow us to use the OAuth APIs from Google, Facebook, Twitter, etc. 
It works in a very simple way, let's take Google as an example:

1. When the user signs in to your app through Google, the app calls Google API that's been previously set up for your app.
2. The user is requested to sign in to Google, and to accept the conditions. 
3. The API then redirects the user to a predefined callback URL in your app, with a JSON reply containing the user info.
4. Your app can then use this data, mainly `provider` (Google) and `uid` (a user ID), to sign in the user.

### Prerequisites
Make sure you have the proper omniauth gems in your Gemfile:
```ruby
gem 'devise', '~>2.0.0'
gem 'omniauth-google-oauth2', '~>0.2.1'
gem 'omniauth-facebook', '~>1.5.1'
```

### Create your Model
Let's first initialize Devise that will be used for our app authentication:
```
$ rails generate devise:install
```
Then do the requested settings.

Devise actually comes with a helper to generate the model:
```
$ rails generate devise User
```

Edit the generated migration file `db/migrate/<timestamp>_devise_create_users` to add the 2 columns below to store the user name and a url to her picture:
```
t.string :name
t.string :avatar
```

Let's generate Devise views while we're here, we'll need them later:
```
$ rails generate devise:views
```

Run the migration with `rake db:migrate`. Alright, we have our User model. If we only wanted to support a single social signin, we would simple add the `provider` and `uid` columns directly in the User model, but we want to support several ones here. We have to store the authentication data somewhere else. An Authentication model sounds right. Let's generate it.

```
$ rails g migration CreateAuthentications user:references:index provider:string uid:string token:string token_secret:string
```

And a `rake:db:migrate` to use this new schema.

Also create the `Authentication` model under `app/models/authentication.rb`:
```ruby
class Authentication < ActiveRecord::Base
  belongs_to :user
end
```

And add a line `has_many :authentications` in `app/models/user.rb`.

### Configure OmniAuth
In the OmniAuth section of `config/initializers/devise.rb`, add the following lines:
```ruby
  config.omniauth :google_oauth2, ENV['GOOGLE_APP_ID'], ENV['GOOGLE_APP_SECRET'],
    { access_type: "offline", approval_prompt: "" }
  config.omniauth :facebook, ENV['FACEBOOK_APP_ID'], ENV['FACEBOOK_APP_SECRET'],
    { scope: 'publish_stream, email', strategy_class: OmniAuth::Strategies::Facebook }
  config.omniauth :twitter, ENV['TWITTER_APP_ID'], ENV['TWITTER_APP_SECRET']
```
You can store the actual variables in a file `config/heroku_env.rb` like that:
```ruby
# This file contains the ENV vars necessary to run the app locally.  
# Some of these values are sensitive, and some are developer specific.
#
# DO NOT CHECK THIS FILE INTO VERSION CONTROL
#
# heroku config:set KEY_1=VALUE_1 KEY_2=VALUE_2 etc...
#

ENV['GOOGLE_APP_ID']     = "blablabla.apps.googleusercontent.com"
ENV['GOOGLE_APP_SECRET'] = "blablablablablablabla"
```

You load those variables in `config/environment.rb` just before the `initialize!` call:
```ruby
# Load heroku vars from local file
heroku_env = File.join(Rails.root, 'config', 'heroku_env.rb')
load(heroku_env) if File.exists?(heroku_env)
```

Finally, register those providers in your User model and make sure you have the `omniauthable` feature:
```ruby
  devise :database_authenticatable, :registerable, :omniauthable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauth_providers => [:google_oauth2, :facebook, :twitter]
```

### Add the views
We'll show the sign in links in a nice popup. Let's code the partial for the content of that popup, in `app/views/shared/_signin_links.html.erb`:
```ruby
<p><strong>Vous pouvez vous enregistrer via un de ces services :</strong></p>

<%= link_to user_omniauth_authorize_path(:google_oauth2) do %>
  <%= image_tag('google_64.png', size: "64x64", alt: "Google") %>
  Google
<% end %>
<%= link_to user_omniauth_authorize_path(:facebook) do %>
  <%= image_tag('facebook_64.png', size: "64x64", alt: "Facebook") %>
  Facebook
<% end %>
<%= link_to user_omniauth_authorize_path(:twitter) do %>
  <%= image_tag('twitter_64.png', size: "64x64", alt: "Twitter") %>
  Twitter
<% end %>
<br />
<br />
<p><strong>Vous n'utilisez pas ses services ?</strong></p>
<p><%= link_to 'Enregistrez-vous', new_user_registration_path %>
ou <%= link_to 'connectez-vous', new_user_session_path %>
avec un mot de passe.</p>
```

Then add the popup near your navbar HTML code:
```erb
<!-- Sign in form -->
<% unless user_signed_in? %>
<div class="modal fade" id="signinModal" tabindex="-1" role="dialog" aria-labelledby="signinModalLabel" aria-hidden="true">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header">
        <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
        <h4 class="modal-title" id="signinModalLabel">Enregistrez-vous</h4>
      </div>
      <div class="modal-body">
        <%= render 'shared/signin_links' %>
      </div>
    </div>
  </div>
</div>
<% end %>
```

Trigger it like this:
```
<%= link_to "S'enregistrer", '#', 'data-toggle' => "modal", 'data-target' => "#signinModal" %>
```

### Configure the routes and controllers
Customize Devise routes in `config/routes.rb`:
```ruby
  devise_for :users,
    controllers: {
      registrations: "registrations",
      omniauth_callbacks: "authentications"
    }
```

### Add the controllers
`app/controllers/authentications_controller.rb`:
```ruby
class AuthenticationsController < Devise::OmniauthCallbacksController

  def try_sign_in_user
    omni = request.env["omniauth.auth"]
    authentication = Authentication.find_by_provider_and_uid(omni['provider'], omni['uid'])
    user = current_user || User.find_by_email(omni.info.email)
    if authentication
      # The user has already authenticated with this provider
      flash.notice = "Bienvenue !"
      sign_in_and_redirect authentication.user
    elsif user
      # The user is currently signed in, but with another provider
      user.add_provider!(omni)
      flash.notice = "Bienvenue !"
      sign_in_and_redirect user
    else
      # No authenticated user, and unknown provider
      user = User.new
      user.apply_omniauth(omni)

      if user.save
        flash.notice = "Bienvenue !"
        sign_in_and_redirect user
      else
        # User validation failed
        # The oauth info did not contain any email (eg, Twitter account)
        # Backup the API data for later use during registration
        session['devise.omniauth'] = omni.except('extra')

        flash.notice = "C'est presque bon ! Entrez un email pour finir votre enregistrement."
        redirect_to new_user_registration_path
      end
    end
  end

  def google_oauth2
    try_sign_in_user
  end

  def facebook
    try_sign_in_user
  end

  def twitter
    try_sign_in_user
  end
end
```

`app/controllers/registrations_controller.rb`:
```ruby
class RegistrationsController < Devise::RegistrationsController
  private
  def build_resource(*args)
    super
    if session["devise.omniauth"]
      @user.apply_omniauth(session["devise.omniauth"])
      @user.valid?
    end
  end
end
```

You'll need the following methods in `app/models/user.rb`:
```ruby
  def add_provider!(auth)
    authentications.create!(
      provider: auth.provider,
      uid: auth.uid,
      token: auth.credentials.token,
      token_secret: auth.credentials.secret
    )
  end

  def apply_omniauth(auth)
    self.name = auth.info.name if name.blank?
    self.email = auth.info.email if email.blank?
    self.avatar = auth.info.image if avatar.blank?
    authentications.build(
      provider: auth.provider,
      uid: auth.uid,
      token: auth.credentials.token,
      token_secret: auth.credentials.secret
    )
  end
 
  def password_required?
    (authentications.empty? || !password.blank?) && super
  end

  # OK to update a user without a password (otherwise validation fails)
  def update_with_password(params, *options)
    if encrypted_password.blank?
      update_attributes(params, *options)
    else
      super
    end
  end
```


You need a few tricks to make this work. First, hide the passwords field when you're only requesting the email to the user who signed up from Twitter (or an API that doesn't return the user's email). In
`app/views/devise/registrations/new.html.erb`, surround the password fields with:
```erb
<% if @user.password_required? %>
  <div><%= f.label :password %><br />
  <%= f.password_field :password %></div>

  <div><%= f.label :password_confirmation %><br />
  <%= f.password_field :password_confirmation %></div>
<% end %>
```

# How I start a Rails app

* [App initialization](#appInit)
* [Git setup](#gitSetup)
* [Initialize RSpec](#specsSetup)
* [Twitter Bootstrap](#bootstrap)
* [Slim templates](#slim)
* [First commit](#firstCommit)
* [Create local DBs](#createDB)
* [If you want to deploy to Heroku](#heroku)

## <a name="appInit"></a>App initialization
Suppress the ri and rdoc documentation in ~/.gemrc:
```
install: --no-rdoc --no-ri
update:  --no-rdoc --no-ri
```

Install the latest version of Rails (at the time of writing: Rails 4.1.6):
```
$ gem install rails
```

Create the app without tests (I use Rspec) and with mysql:
```
$ rails new my_app -T -d mysql
```

My initial Gemfile includes a few added gems, and Rspec/Capybara/Selenium for tests:
```ruby
source 'https://rubygems.org'
ruby '2.1.3'

gem 'rails', '4.1.6'
gem 'mysql2'
gem 'sass-rails', '~> 4.0.3'
gem 'uglifier', '>= 1.3.0'
gem 'coffee-rails', '~> 4.0.0'
gem 'jquery-rails'
gem 'turbolinks'
gem 'jbuilder', '~> 2.0'

# Improvement gems
gem 'slim-rails'
gem 'bootstrap-sass'
gem 'autoprefixer-rails'
gem 'font-awesome-rails'
gem 'simple_form'
gem 'dotenv-rails'

# Social sign-in
gem 'devise'
gem 'omniauth-google-oauth2'
gem 'omniauth-facebook'
gem 'omniauth-twitter'

group :production do
  gem 'rails_12factor', '0.0.2' # To deploy on Heroku
end

group :development do
  gem 'spring'
  gem 'better_errors'
  gem 'quiet_assets'
end

group :development, :test do
  gem 'rspec-rails'
end

group :test do
  gem 'selenium-webdriver'
  gem 'capybara'
  gem 'factory_girl_rails'
  gem 'simplecov', require: false
end
```


## <a name="gitSetup"></a>Git setup
Some commands I always run:
```
$ git config --global user.name "Your Name"
$ git config --global user.email your.email@example.com
$ git config --global alias.co checkout
$ git config --global color.ui true
```

Default .gitignore:
```
# Ignore bundler config.
/.bundle

# Ignore the environment and secret files.
/.env
secrets.yml

# Ignore DB backups.
/db/*.bak

# Ignore all logfiles and tempfiles.
/log/*.log
/tmp
/coverage
/tags
```

## <a name="specsSetup"></a>Initialize specs
```
rails generate rspec:install
```
And if you want to generate test coverage on every test run, add the following to lines at the top of `spec/spec_helper.rb`:
```
require 'simplecov'
SimpleCov.start
```

## <a name="bootstrap"></a>Twitter Bootstrap
Create a new file called `app/assets/stylesheets/bootstrap_custom.css.scss` containing the import of the bootstrap files and any customization you might need:
```scss
$brand-primary: #8E44AD;

@import "bootstrap-sprockets";
@import "bootstrap";
```

And update `app/assets/javascripts/application.js` to include Bootstrap:
```js
//= require jquery
//= require jquery_ujs
//= require turbolinks
//= require bootstrap-sprockets
//= require_tree .
```

## <a name="slim"></a>Slim templates
Since you put the gem 'slim-rails' in your `Gemfile`, all new view files will be generated with the slim template (much faster and simpler to use!). But you still need to give a slim extension and update the `app/views/layouts/application.html.erb` that got generated when initializing the app. I recommend splitting this layout already:

```
# app/views/layouts/application.html.slim
doctype html
html
  = render "layouts/head"
  body
    = render "layouts/navbar"
    .container
      = yield
    #footer
      .container
        br
        p.text-muted &copy; MyApp 2014
```        

```
# app/views/layouts/_head.html.slim
head
  title Smart Social Buffer
  meta charset="utf-8"
  meta content="width=device-width, initial-scale=1.0" name="viewport"
  = stylesheet_link_tag 'application', media: 'all', 'data-turbolinks-track' => true
  = javascript_include_tag 'application', 'data-turbolinks-track' => true
  = csrf_meta_tags
```   

```
# app/views/layouts/_navbar.html.slim
.navbar.navbar-default.navbar-static-top*{role: 'navigation'}
  .container
    .navbar-header
      button.navbar-toggle*{type: 'button', data: {toggle: 'collapse', target: '.navbar-collapse'}}
        span.sr-only Toggle navigation
        span.icon-bar
        span.icon-bar
        span.icon-bar
      = link_to root_path, class: 'navbar-brand' do
        = image_tag 'logo.png', alt: "My App"
    .collapse.navbar-collapse
      ul.nav.navbar-nav
        li.active = link_to 'Home', '#'
        li = link_to 'About', '#'
        li = link_to 'Contact', '#'
```   

## <a name="firstCommit"></a>First commit
```
$ git init
$ git add .
$ git commit -m "Initialize repository."
$ git remote add origin https://github.com/jibai31/my_app.git
$ git push -u origin master
```


## <a name="createDB"></a>Create local DBs
```
$ bin/rake db:create
$ git push heroku master
```

## <a name="heroku"></a>Heroku
Follow the additional steps [here](heroku.md) if you're deploying to Heroku.


# How I start a Rails app

## App initialization
Suppress the ri and rdoc documentation in ~/.gemrc:
```
install: --no-rdoc --no-ri
update:  --no-rdoc --no-ri
```

Install the latest version of Rails (at the time of writing: Rails 4.1.6):

    $ gem install rails

Create the app without tests (I use Rspec) and with mysql:

    $ rails new my_app -T -d mysql

My initial Gemfile includes a few added gems, and Rspec/Capybara/Selenium for tests:
```ruby
source 'https://rubygems.org'
ruby '2.1.3'

gem 'rails', '4.1.6'
gem 'mysql2'
# gem 'pg', '0.15.1'
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


## Git setup
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

## Initialize specs
```
rails generate rspec:install
```
And if you want to generate test coverage on every test run, add the following to lines at the top of `spec/spec_helper.rb`:
```
require 'simplecov'
SimpleCov.start
```

## First commit
```
$ git init
$ git add .
$ git commit -m "Initialize repository."
$ git remote add origin https://github.com/jibai31/my_app.git
$ git push -u origin master
```


## Create local DBs
```
$ bin/rake db:create
$ git push heroku master
```

## Heroku
If you're deploying on Heroku you probably want the pg gem to use PostreSQL.

We're using Postgres locally, so we need to create the DBs manually. Let's first update `config/database.yml`:
```yml
development:
  adapter: postgresql
  encoding: unicode
  database: my_app_development
  pool: 5
  username: postgres
  password: 

# Warning: The database defined as "test" will be erased and
# re-generated from your development database when you run "rake".
# Do not set this db to the same as development or production.
test:
  adapter: postgresql
  encoding: unicode
  database: my_app_test
  pool: 5
  username: postgres
  password:

production:
  adapter: postgresql
  encoding: unicode
  database: my_app_production
  pool: 5
  username: postgres
  password: 
```
NB: Heroku regenerates `config/database.yml` when you deploy your code there.

Then run the following commands to create empty DBs:
```
$ createdb -U postgres antigone_development
$ createdb -U postgres antigone_test
$ createdb -U postgres antigone_production
```

#### Create your own user
If the user role 'postgres' doesn't have enough rights to create the databases, you should create your own user role:
```
$ sudo su postgres -c psql
> CREATE ROLE vagrant SUPERUSER LOGIN;
> \q
```

Then in your database.yml file, use that user instead, without any password:
```
  username: vagrant
  password:
```

Finally deploy the app to Heroku:
```
$ heroku create
$ git push heroku master
```

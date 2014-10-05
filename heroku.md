# Deploy on Heroku

If you're deploying on Heroku you probably want the pg gem to use PostreSQL. Add it to your `Gemfile` instead of sqlite3 or mysql:
```ruby
gem 'pg', '0.15.1'
```

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

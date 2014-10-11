### Write the test scenarios first

#### Mock the signin APIs for tests
In your `spec/spec_helper.rb`, add the following line before the `RSpec.configure` block:
```
# Mock all OmniAuth calls
OmniAuth.config.test_mode = true
```

#### Create the following 2 features
`spec/features/visitor_signs_up_spec.rb`:
```ruby
require 'spec_helper'

feature 'Visitor signs up' do
  scenario 'with valid email and password' do
    sign_up_with 'valid@example.com', 'password'

    user_should_be_signed_in
  end

  scenario 'with invalid email' do
    sign_up_with 'invalid_email', 'password'

    user_should_be_signed_out
  end

  scenario 'with blank password' do
    sign_up_with 'valid@example.com', ''

    user_should_be_signed_out
  end 

  scenario 'with Google' do
    sign_in_with_provider "Google"

    user_should_be_signed_in
  end

  scenario 'with Twitter' do
    sign_in_with_provider "Twitter"
    fill_in "Email", with: "john.doe@twitter.com"
    click_button 'Sign up'

    user_should_be_signed_in
  end
end
```

And `spec/features/visitor_signs_in_spec.rb`:
```ruby
require 'spec_helper'

feature 'Visitor signs in' do

  scenario 'with Google' do
    create_user 'john.doe@example.com', 'password', 'John Smith'
    sign_in_with_provider 'Google'

    user_should_be_signed_in_as 'John Smith'
  end

  scenario 'with Twitter' do
    create_user_with_provider 'john.doe@twitter.com', 'twitter'
    sign_in_with_provider 'Twitter'

    user_should_be_signed_in
  end

  scenario 'with Facebook after a Google signin' do
    create_user_with_provider 'john.doe@example.com', 'google_oauth2', 'John Smith'
    sign_in_with_provider 'Facebook'

    user_should_be_signed_in_as 'John Smith'
  end
end
```

Those scenarios look very simple because some implementation details got extracted into helpers in `spec/support/session_macros.rb`:
```ruby
module SessionMacros

  # === ARRANGE HELPERS =========================================

  def create_user(email, password, name = nil)
    FactoryGirl.create(:user, email: email, password: password, name: name)
  end

  def create_user_with_provider(email, provider, name = nil)
    FactoryGirl.create(:user_with_authentication, email: email, name: name)
  end
  # === ACT HELPERS =============================================

  def sign_up_with(email, password, password_confirmation = nil)
    password_confirmation ||= password
    visit new_user_registration_path
    fill_in 'Email', with: email
    fill_in 'Password', with: password
    fill_in 'Password confirmation', with: password_confirmation
    click_button 'Sign up'
  end

  def sign_in_with(email, password)
    visit new_user_session_path
    fill_in "Email", with: email
    fill_in "Password", with: password
    click_link "Sign in"
  end

  def sign_in_with_provider(provider)
    visit root_path
    click_link provider
  end

  # === ASSERT HELPERS ==========================================

  def user_should_be_signed_in
    expect(page).to have_content('Se déconnecter')
  end

  def user_should_be_signed_in_as name
    user_should_be_signed_in
    expect(page).to have_content(name)
  end

  def user_should_be_signed_out
    expect(page).to have_content("S'enregistrer")
  end

  def page_should_display_sign_in_error
    page.should have_css('div.error', 'Incorrect email or password')
  end

end
```

Make sure that this helper is available to your specs. Add the following line within the `RSpec.configure` block in `spec/spec_helper.rb`:
```ruby
# Include macros
config.include SessionMacros
```

And some factories in `spec/factories.rb`:
```ruby
# More info:
# https://github.com/thoughtbot/factory_girl/blob/master/GETTING_STARTED.md

OmniAuth.config.mock_auth[:twitter] = OmniAuth::AuthHash.new({
  provider: 'twitter',
  uid: '12345',
  info: { name: 'John Doe', image: '' },
  credentials: { token: "abc_def", secret: "123_456" }
})

OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
  provider: 'google_oauth2',
  uid: '12345',
  info: { email: 'john.doe@example.com', name: 'John Doe', image: '' },
  credentials: { token: "abc_def", secret: "123_456" }
})

OmniAuth.config.mock_auth[:facebook] = OmniAuth::AuthHash.new({
  provider: 'facebook',
  uid: '12345',
  info: { email: 'john.doe@example.com', name: 'John Doe', image: '' },
  credentials: { token: "abc_def", secret: "123_456" }
})

FactoryGirl.define do
  factory :user do
    email     "john.doe@example.com"
    name      "John Doe"
    password  "password"

    factory :user_with_authentication do
      ignore do
        provider "twitter"
      end
      after(:create) do |user, evaluator|
        FactoryGirl.create(:authentication, user: user, provider: evaluator.provider)
      end
    end
  end

  factory :authentication do
    provider "provider"
    uid "12345"
    user
  end

end
```

Run the tests. They all fail? Good, let's move on.

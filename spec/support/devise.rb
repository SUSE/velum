# frozen_string_literal: true

# DeviseMock is a module that provides methods used as helpers in devise-related
# views.
module DeviseMock
  def resource
    User.new
  end

  def resource_name
    :user
  end

  def devise_mapping
    Devise.mappings[:user]
  end
end

# Setup devise for tests.
RSpec.configure do |config|
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Devise::Test::ControllerHelpers, type: :view

  # Needed for methods such as `login_as`.
  config.include Warden::Test::Helpers
  config.before(:suite) { Warden.test_mode! }
end

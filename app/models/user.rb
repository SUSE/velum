# frozen_string_literal: true
# User represents administrators in this application.
class User < ApplicationRecord
  enabled_devise_modules = [:database_authenticatable, :registerable,
                            :rememberable, :trackable, :validatable].freeze

  devise(*enabled_devise_modules)

  def ec2_configuration_parsed
    ec2_configuration ? JSON.parse(ec2_configuration) : {}
  end
end

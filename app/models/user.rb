# frozen_string_literal: true
# User represents administrators in this application.
class User < ApplicationRecord
  enabled_devise_modules = [:database_authenticatable, :registerable,
                            :recoverable, :rememberable, :trackable, :validatable].freeze

  devise(*enabled_devise_modules)

  validates :email, presence: true, uniqueness: true
end

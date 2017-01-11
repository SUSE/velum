# frozen_string_literal: true
# User represents administrators in this application.
class User < ApplicationRecord
  enabled_devise_modules = [:database_authenticatable, :registerable,
                            :recoverable, :rememberable, :trackable, :validatable,
                            authentication_keys: [:name]]

  devise(*enabled_devise_modules)

  validates :name, :email, presence: true, uniqueness: true
end

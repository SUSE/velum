# frozen_string_literal: true
require "pharos/salt"

# DashboardController shows the main page.
class DashboardController < ApplicationController
  def index
    salt = Pharos::Salt.new

    @minions = salt.minions
  end
end

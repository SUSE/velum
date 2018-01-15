# Allows to re-run upgrade orchestrations
class Orchestrations::UpgradeController < ApplicationController
  before_action :check_orchestration_can_be_retried, only: :create

  def create
    Orchestration.run kind: :upgrade
    redirect_to root_path
  end

  private

  def check_orchestration_can_be_retried
    redirect_to root_path unless Orchestration.retryable? kind: :upgrade
  end
end

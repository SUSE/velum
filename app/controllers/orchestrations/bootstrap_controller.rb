# Allows to re-run bootstrap orchestrations
class Orchestrations::BootstrapController < ApplicationController
  before_action :check_orchestration_can_be_retried, only: :create

  def create
    Orchestration.run kind: :bootstrap
    redirect_to root_path
  end

  private

  def check_orchestration_can_be_retried
    redirect_to root_path unless Orchestration.retryable? kind: :bootstrap
  end
end

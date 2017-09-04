# frozen_string_literal: true

# OrchestrationsController allows to handle orchestrations
class OrchestrationsController < ApplicationController
  before_action :check_orchestration_can_be_retried, only: :create

  def create
    Orchestration.run
    redirect_to root_path
  end

  private

  def check_orchestration_can_be_retried
    redirect_to root_path unless Orchestration.retryable?
  end
end

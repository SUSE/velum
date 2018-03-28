# Allows to manage Minions
class MinionsController < ApplicationController
  before_action :fetch_minion

  def destroy
    Orchestration.run kind: :removal, params: { target: @minion.minion_id }
    render nothing: true, status: :no_content
  rescue Orchestration::OrchestrationOngoing
    render text:   "Orchestration currently ongoing. Please wait for it to finish.",
           status: :unprocessable_entity
  end

  def force_destroy
    Orchestration.run kind: :force_removal, params: { target: @minion.minion_id }
    render nothing: true, status: :no_content
  rescue Orchestration::OrchestrationOngoing
    render text:   "Orchestration currently ongoing. Please wait for it to finish.",
           status: :unprocessable_entity
  end

  private

  def fetch_minion
    @minion = Minion.find_by! minion_id: params[:id]
  end
end

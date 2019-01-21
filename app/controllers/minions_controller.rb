# Allows to manage Minions
class MinionsController < ApplicationController
  before_action :not_implemented_in_public_cloud
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

  # Public Cloud frameworks do not currently support removing nodes
  def not_implemented_in_public_cloud
    return unless in_public_cloud?
    render nothing: true, status: :not_implemented
  end

  def fetch_minion
    @minion = Minion.find_by! minion_id: params[:id]
  end
end

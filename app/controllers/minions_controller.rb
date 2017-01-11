class MinionsController < ApplicationController

  def index
    render json: { minions: Minion.all }
  end

end

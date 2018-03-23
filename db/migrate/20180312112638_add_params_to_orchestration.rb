class AddParamsToOrchestration < ActiveRecord::Migration
  def change
    add_column :orchestrations, :params, :text, after: :kind
  end
end

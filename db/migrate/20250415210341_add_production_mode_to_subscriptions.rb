class AddProductionModeToSubscriptions < ActiveRecord::Migration[7.1]
  def change
    add_column :subscriptions, :production_mode, :boolean, default: false
  end
end

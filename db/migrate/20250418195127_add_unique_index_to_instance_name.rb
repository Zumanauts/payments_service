class ChangeSubscriptionIdSubscriptionStatus < ActiveRecord::Migration[7.1]
  def change
    remove_index :subscriptions, :portal_instance_name
    add_index :subscriptions, [:portal_instance_name, :production_mode], unique: true
  end
end

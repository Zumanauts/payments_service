class ChangeSubscriptionIdSubscriptionStatus < ActiveRecord::Migration[7.1]
  def change
    add_column :subscription_statuses, :stripe_subscription_id, :string
    remove_reference :subscription_statuses, :subscriptions
  end
end

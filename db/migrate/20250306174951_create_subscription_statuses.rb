class CreateSubscriptionStatuses < ActiveRecord::Migration[7.1]
  def change
    create_table :subscription_statuses do |t|

      t.references :subscriptions
      t.references :stripe_event
      t.date :current_period_start_date
      t.date :current_period_end_date
      t.string :status
      t.timestamps
    end
  end
end

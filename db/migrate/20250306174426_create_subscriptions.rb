class CreateSubscriptions < ActiveRecord::Migration[7.1]
  def change
    create_table :subscriptions do |t|

      t.json :signup_form_data
      t.string :portal_instance_name, index: { unique: true }
      t.string :stripe_subscription_id, index: { unique: true }
      t.string :stripe_customer_id, index: { unique: true }
      t.timestamps

    end
  end
end

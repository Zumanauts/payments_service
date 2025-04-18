class UpdateSubscriptions < ActiveRecord::Migration[7.1]
  def change
    remove_column :subscriptions, :signup_form_data
    add_reference :subscriptions, :subscription_request

    remove_index :subscriptions, :portal_instance_name
    add_index :subscriptions, [:portal_instance_name, :production_mode], unique: true
  end
end

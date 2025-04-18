class CreateSubscriptionRequests < ActiveRecord::Migration[7.1]
  def change
    create_table :subscription_requests do |t|

      t.json :signup_form_data
      t.string :reference_id
      t.boolean :production_mode, default: false

      t.timestamps

    end
  end
end

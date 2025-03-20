class CreateStripeEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :stripe_events do |t|

      t.string :event_type
      t.json :event_data
      t.timestamps
    end
  end
end

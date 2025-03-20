class SubscriptionStatus < ApplicationRecord

  belongs_to :subscription
  belongs_to :stripe_event

end

class Subscription < ApplicationRecord

  has_many :subscription_statuses

  #Random number so reference ids provided to stripe does not start from 1
  CLIENT_REF_ID_SEQ_START = 190670

  def reference_id
    raise "Subscription have no id yet" if new_record?
    id + CLIENT_REF_ID_SEQ_START
  end

  def self.find_by_reference_id(ref_id)
    find(ref_id.to_i - CLIENT_REF_ID_SEQ_START)
  end

end

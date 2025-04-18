class SubscriptionRequest < ApplicationRecord

  has_one :subscription
  before_create :validate_form
  after_create :create_ref_id

  def create_ref_id
    self.update_attribute(:reference_id, SecureRandom.hex(4)+id.to_s)
  end


  def validate_form

    raise "Missing email" if signup_form_data["Email"].nil?
    signup_form_data["Email"] = signup_form_data["Email"].downcase
    signup_form_data["Confirm-Email"] = signup_form_data["Confirm-Email"].downcase

    raise "Emails do not match" if signup_form_data["Email"] != signup_form_data["Confirm-Email"]

    raise "Company name not provided" unless company_name.present?

  end

  def company_name
    signup_form_data["Company-Legal-Name"]
  end



end

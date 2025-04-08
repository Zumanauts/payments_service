class SubscriptionController < ApplicationController

  STRIPE_MONTHLY_LINK = "https://buy.stripe.com/7sIdTBc4IcL9eis3cc"

  ANNUAL_SUBSCRIPTION_CODE = "price_1QyTnJIX0USGAO7Lz5v69drc"
  MONTHLY_SUBSCRIPTION_CODE = "price_1QyTm1IX0USGAO7L4HFjXLvQ"

  TABULERA_SUCCESS_URL = "https://tabulera.com/checkout-success"
  TABULERA_FAIL_URL = "https://tabulera.com/checkout-cancel"

  skip_before_action :verify_authenticity_token

  def create_session

    f_params = form_params

    #Validate params
    transform_params f_params

    is_monthly = f_params["Selected Plan"]&.split(' ')&.last != "annual"

    pp form_params

    product_code = is_monthly ? MONTHLY_SUBSCRIPTION_CODE : ANNUAL_SUBSCRIPTION_CODE

    company_name = f_params["Company-Legal-Name"]
    raise "Company name not provided" if company_name.nil?

    instance_name = generate_portal_instance_name(company_name)

    subscription_model = create_subscription f_params, instance_name

    session = Stripe::Checkout::Session.create({
                                                 success_url: TABULERA_SUCCESS_URL,
                                                 cancel_url: TABULERA_FAIL_URL,
                                                 mode: 'subscription',
                                                 line_items: [{
                                                                  # For metered billing, do not pass quantity
                                                                  quantity: 1,
                                                                  price: product_code,
                                                              }],
                                                 metadata: {
                                                     tabulera_subscription_id: subscription_model.reference_id
                                                 }
                                             })

    redirect_to session.url, allow_other_host: true
  end

  def test_create

    instance_name = generate_portal_instance_name("abc")

    subscription_model = create_subscription({}, instance_name)

    session = Stripe::Checkout::Session.create({
                                                   success_url: TABULERA_SUCCESS_URL,
                                                   cancel_url: TABULERA_FAIL_URL,
                                                   mode: 'subscription',
                                                   line_items: [{
                                                                    # For metered billing, do not pass quantity
                                                                    quantity: 1,
                                                                    price: MONTHLY_SUBSCRIPTION_CODE,
                                                                }],
                                                   metadata: {
                                                       tabulera_subscription_id: subscription_model.reference_id
                                                   },
                                                   subscription_data: {
                                                       trial_period_days: 30
                                                   }
                                               })

    redirect_to session.url, allow_other_host: true

  end



  def customer_portal_link

    # instance_name = params[:instance_name]
    # return status 400 if instance_name.nil?
    #
    # subscription = Subscription.where(portal_instance_name: instance_name).first
    # return status 400 if subscription.nil?
    #
    # session = Stripe::BillingPortal::Session.create(
    #     customer: subscription.stripe_customer_id,
    #     return_url: "https://#{subscription.portal_instance_name}.tabulera.com/"
    # )
    #
    # render json: {portal_url: session.url}


    session = Stripe::BillingPortal::Session.create(
        customer: "cus_Rvoi8nwTu3LgEx",
        return_url: "https://stage-sandisk.tabulera.com/"
    )

    render json: {portal_url: session.url}

  end


  def test_customer_portal_link

    session = Stripe::BillingPortal::Session.create(
        customer: "cus_Rvoi8nwTu3LgEx",
        return_url: "https://stage-sandisk.tabulera.com/"
    )

    render json: {portal_url: session.url}
  end


  rescue_from StandardError do |e|
    puts "Error during processing: #{$!}"
    puts "Backtrace:\n\t#{e.backtrace.join("\n\t")}"
    redirect_to TABULERA_FAIL_URL, allow_other_host: true
  end

  private

  def transform_params form

    raise "Missing email" if form["Email"].nil?
    form["Email"] = form["Email"].downcase
    form["Confirm-Email"] = form["Confirm-Email"].downcase

    raise "Emails do not match" if form["Email"] != form["Confirm-Email"]

    address = [form.delete("Company-Address-1").presence,
               form.delete("Company-Address-2").presence]

    form["Company-Address"] = address.compact.join(", ")

    #Add more validation logic here
  end

  def generate_portal_instance_name company_name

    company_name_normalized = company_name.gsub(/[^0-9a-z]/i, '')

    company_name_components = company_name_normalized.gsub(/[[:upper:]]/, ' \0').gsub('  ', ' ').strip.split(' ')

    if company_name_components.count >= 3
      suggested_name = company_name_components.map {|c|c[0]}.join('').downcase
    else
      suggested_name = company_name_normalized.gsub(' ', '').downcase
    end
    "saas-" + suggested_name
  end


  def create_subscription signup_form_data, instance_name

    full_instance_name = instance_name
    subscription_model = nil
    attempts = 0


    loop do
      begin
        subscription_model = Subscription.create(signup_form_data: signup_form_data, portal_instance_name: full_instance_name)
        break;
      rescue ActiveRecord::RecordNotUnique
        full_instance_name = instance_name + '-' + SecureRandom.hex(2)
      end
      attempts += 1
      raise "Failed to generate uniq domain" if attempts > 10
    end

    subscription_model

  end

  def form_params
    params.permit("First-Name", "Last-Name", "Email", "Confirm-Email", "Company-Legal-Name", "EIN", "Company-Address",
                  "State", "Postal-Code", "Selected Plan").to_h
  end

end

class SubscriptionController < ApplicationController

  ANNUAL_SUBSCRIPTION_CODE = ENV["ANNUAL_SUBSCRIPTION_CODE"]
  MONTHLY_SUBSCRIPTION_CODE = ENV["MONTHLY_SUBSCRIPTION_CODE"]

  TABULERA_SUCCESS_URL = "https://tabulera.com/checkout-success"
  TABULERA_FAIL_URL = "https://tabulera.com/checkout-cancel"

  PRODUCTION_MODE = !!ENV["PRODUCTION_MODE"]

  skip_before_action :verify_authenticity_token


  def create_session

    signup_form = form_params

    product_code = is_monthly_param ? MONTHLY_SUBSCRIPTION_CODE : ANNUAL_SUBSCRIPTION_CODE

    instance_name = SubscriptionService.generate_portal_instance_name(company_name_param, PRODUCTION_MODE)

    subscription_model = SubscriptionService.create_subscription(signup_form, instance_name, PRODUCTION_MODE)

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



  def create_server

    singup_form = form_params

    instance_name = SubscriptionService.generate_portal_instance_name(company_name_param, is_prod_param)

    subscription_model = SubscriptionService.create_subscription(signup_form, instance_name, is_prod_param)

    tabuleraAdminService = TabuleraAdminService.from_config
    tabuleraAdminService.create_portal_instance instance_name, singup_form, is_prod_param

    redirect_to TABULERA_SUCCESS_URL, allow_other_host: true

  end



  def customer_portal_link

    instance_name = params[:instance_name]
    return status 400 if instance_name.nil?

    subscription = Subscription.where(portal_instance_name: instance_name).first
    return status 400 if subscription.nil?

    portal_host = SubscriptionService.portal_host subscription.portal_instance_name, subscription.production_mode

    session = Stripe::BillingPortal::Session.create(
        customer: subscription.stripe_customer_id,
        return_url: "https://#{portal_host}/"
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

  def is_monthly_param
    @is_monthly ||= params["Selected Plan"]&.split(' ')&.last != "annual"
  end


  def company_name_param
    @company_name ||= params["Company-Legal-Name"]
    raise "Company name not provided" if @company_name.nil?
    @company_name
  end


  def is_prod_param
    @is_stage ||= (params["prod"] == "true")
  end


  def transform_params form

    raise "Missing email" if form["Email"].nil?
    form["Email"] = form["Email"].downcase
    form["Confirm-Email"] = form["Confirm-Email"].downcase

    raise "Emails do not match" if form["Email"] != form["Confirm-Email"]

    #Add more validation logic here
  end


  def form_params
    signup_form = params.permit("First-Name", "Last-Name", "Email", "Confirm-Email", "Company-Legal-Name",
                                "EIN", "Company-Address-1", "Company-Address-2", "City","State", "Postal-Code",
                                "Selected Plan").to_h

    pp signup_form

    transform_params signup_form

    signup_form
  end

end

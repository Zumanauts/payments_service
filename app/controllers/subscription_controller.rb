class SubscriptionController < ApplicationController

  ANNUAL_SUBSCRIPTION_CODE = ENV["ANNUAL_SUBSCRIPTION_CODE"]
  MONTHLY_SUBSCRIPTION_CODE = ENV["MONTHLY_SUBSCRIPTION_CODE"]

  TABULERA_SUCCESS_URL = "https://tabulera.com/checkout-success"
  TABULERA_CANCEL_URL = "https://tabulera.com/checkout-account-details?"
  TABULERA_FAIL_URL = "https://tabulera.com/checkout-fail"


  PRODUCTION_MODE = !!ENV["PRODUCTION_MODE"]

  skip_before_action :verify_authenticity_token


  def create_session

    signup_form = form_params

    product_code = is_monthly_param ? MONTHLY_SUBSCRIPTION_CODE : ANNUAL_SUBSCRIPTION_CODE

    subscription_request = SubscriptionRequest.create(signup_form_data: signup_form, production_mode: PRODUCTION_MODE)

    cancel_url = TABULERA_CANCEL_URL + cancel_params

    session = Stripe::Checkout::Session.create({
                                                 success_url: TABULERA_SUCCESS_URL,
                                                 cancel_url: cancel_url,
                                                 mode: 'subscription',
                                                 line_items: [{
                                                                  # For metered billing, do not pass quantity
                                                                  quantity: 1,
                                                                  price: product_code,
                                                              }],
                                                 subscription_data: {
                                                  trial_period_days: 30 #Tmp
                                                 },
                                                 metadata: {
                                                     tabulera_subscription_id: subscription_request.reference_id
                                                 }
                                             })

    redirect_to session.url, allow_other_host: true
  end



  def create_server

    signup_form = form_params

    subscription_request = SubscriptionRequest(signup_form_data: signup_form, production_mode: is_prod_param)
    subscription_model = SubscriptionService.create_subscription({}, subscription_request.company_name, is_prod_param)

    tabuleraAdminService = TabuleraAdminService.from_config
    tabuleraAdminService.create_portal_instance subscription_model.portal_instance_name, signup_form, is_prod_param

    redirect_to TABULERA_SUCCESS_URL, allow_other_host: true

  end



  def customer_portal_link

    instance_name = params[:namespace]
    return head(:bad_request) if instance_name.nil?

    subscription = Subscription.where(portal_instance_name: instance_name).first
    return head(:bad_request) if subscription.nil?

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
        return_url: "https://demo1.tabulera.com/"
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


  def is_prod_param
    @is_stage ||= (params["prod"] == "true")
  end


  def form_params
    params.permit("First-Name", "Last-Name", "Email", "Confirm-Email", "Company-Legal-Name",
                  "EIN", "Company-Address-1", "Company-Address-2", "City","State", "Postal-Code",
                  "Selected Plan").to_h
  end

  def cancel_params

    row_params = params["Selected Plan"] || ""

    row_params.downcase.split(",").map do |param|
      param.split(":").map{|keyVal| keyVal.strip}.join("=")
    end.join("&")
  end

end

class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token


  def process_event
    payload = request.body.read
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']
    event = nil

    begin

      secret = ENV['STRIPE_SECRET']

      event = Stripe::Webhook.construct_event(
          payload, sig_header, 'whsec_LXm3afVnyf2EVxxvcYQUWbW9sW9wKeUp'
      )
    rescue JSON::ParserError => e
      # Invalid payload
      pp "Parsing failed"
      render json: { error: { message: e.message }}, status: :bad_request
      return
    rescue Stripe::SignatureVerificationError => e
      # Invalid signature
      pp "Signature failed", e.message
      render json: { error: { message: e.message, extra: "Sig verification failed" }}, status: :bad_request
      return
    end

    pp "Data extracted"


    event_type = event['type']
    data = event['data']
    data_object = data['object']

    se = StripeEvent.create(event_type: event_type, event_data: data_object)
    pp "------------------------------------", event_type

    case event_type
    when 'checkout.session.completed'

      # Payment is successful and the subscription is created.
      # You should provision the subscription and save the customer ID to your database.

      event_meta_data = data_object['metadata'] || {}
      ref_id = event_meta_data['tabulera_subscription_id']
      raise "Tabulera Ref Id not found" if ref_id.nil?

      stripe_subscription_id = data_object['subscription']
      raise "Subscription Id not found" if stripe_subscription_id.nil?

      stripe_customer_id = data_object['customer']
      # raise "Customer Id not found" if stripe_customer_id.nil?

      subscription_model = Subscription.find_by_reference_id(ref_id)
      raise "Subscription not found" if subscription_model.nil?

      subscription_model.update(stripe_subscription_id: stripe_subscription_id, stripe_customer_id: stripe_customer_id)
      # SubscriptionStatus.create(subscription: subscription_model, stripe_event: se, status: 'trial',
      #                           period_start: period_start, period_end: period_end)
      puts "--------------------","Starting the server"

      # tabuleraAdminService = TabuleraAdminService.from_config
      # tabuleraAdminService.create_portal_instance subscription_model.portal_instance_name,
      #                                             scription_model.signup_form_data, subscription_model.production_mode


    when 'invoice.paid'
      # Continue to provision the subscription as payments continue to be made.
      # Store the status in your database and check when a user accesses your service.
      # This approach helps you avoid hitting rate limits.

      stripe_subscription_id = data_object['subscription']
      period = data_object.dig('lines', 'data', '0', 'period')
      period_start = Time.at(period['start']).to_date unless period.nil?
      period_end = Time.at(period['end']).to_date unless period.nil?

      SubscriptionStatus.create(stripe_subscription_id: stripe_subscription_id, status: 'active', stripe_event: se,
                                period_start: period_start, period_end: period_end)


    when 'invoice.payment_failed'
      # The payment failed or the customer does not have a valid payment method.
      # The subscription becomes past_due. Notify your customer and send them to the
      # customer portal to update their payment information.
    when 'customer.subscription.updated'

      stripe_subscription_id = data_object['id']
      period_start = Time.at(data_object['current_period_start']).to_date
      period_end = Time.at(data_object['current_period_end']).to_date
      status = data_object['status']

      SubscriptionStatus.create(stripe_subscription_id: stripe_subscription_id, status: status, stripe_event: se,
                                period_start: period_start, period_end: period_end)

    else
      puts "Unhandled event type: #{event.type}"
    end


    render json: { message: :success }
  end


  rescue_from StandardError do |e|
    puts "Error during processing: #{$!}"
    puts "Backtrace:\n\t#{e.backtrace.join("\n\t")}"
  end



  private

  def endpoint_secret
    (Rails.application.credentials.dig(:stripe, :signing_secret) || []).first
  end
end

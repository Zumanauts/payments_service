class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token



  def process_event
    payload = request.body.read
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']
    event = nil

    begin
      event = Stripe::Webhook.construct_event(
          payload, sig_header, "whsec_216a164ee9794189c2f8546f7deb6e8caaa198796708fb054655aa9e0b29d1ce"
      )
    rescue JSON::ParserError => e
      # Invalid payload
      render json: { error: { message: e.message }}, status: :bad_request
      return
    rescue Stripe::SignatureVerificationError => e
      # Invalid signature
      render json: { error: { message: e.message, extra: "Sig verification failed" }}, status: :bad_request
      return
    end

    event_type = event['type']
    data = event['data']
    data_object = data['object']

    se = StripeEvent.create(event_type: event_type, event_data: data_object)
    pp "------------------------------------", event_type

    case event_type
    when 'checkout.session.completed'

      puts "--------------------","Checkout completed"


      # Payment is successful and the subscription is created.
      # You should provision the subscription and save the customer ID to your database.

      ref_id = data_object.dig('metadata', 'tabulera_subscription_id')
      raise "Tabulera Ref Id not found" if ref_id.nil?

      stripe_subscription_id = data_object['subscription']
      raise "Subscription Id not found" if stripe_subscription_id.nil?

      stripe_customer_id = data_object['customer']
      # raise "Customer Id not found" if stripe_customer_id.nil?

      period_start = Time.at(data_object['period_start'])&.to_date
      period_end = Time.at(data_object['period_end'])&.to_date


      subscription_model = Subscription.find_by_reference_id(ref_id)
      raise "Subscription nt found" if subscription_model.nil?

      subscription_model.update(stripe_subscription_id: stripe_subscription_id, stripe_customer_id: stripe_customer_id)
      # SubscriptionStatus.create(subscription: subscription_model, stripe_event: se, status: 'trial',
      #                           period_start: period_start, period_end: period_end)
      puts "--------------------","Starting the server"

      tabuleraAdminService = TabuleraAdminService.from_config
      tabuleraAdminService.create_portal_instance instance_name, subscription_model.signup_form_data


    when 'invoice.paid'
      # Continue to provision the subscription as payments continue to be made.
      # Store the status in your database and check when a user accesses your service.
      # This approach helps you avoid hitting rate limits.
      stripe_subscription_id = data_object['subscription']
      # period_start = Time.at(data_object['period_start']).to_date
      # period_end = Time.at(data_object['period_end']).to_date

      # subscription_model = Subscription.find_by_stripe_subscription_id(stripe_subscription_id)
      # raise "Subscription not found" if subscription_model.nil?

      # SubscriptionStatus.create(subscription: subscription_model, status: 'paid', stripe_event: se,
      #                           period_start: period_start, period_end: period_end)


    when 'invoice.payment_failed'
      SubscriptionStatus.create(subscription: subscription_model, status: 'failed', stripe_event: se)

      # The payment failed or the customer does not have a valid payment method.
      # The subscription becomes past_due. Notify your customer and send them to the
      # customer portal to update their payment information.
    when 'customer.subscription.updated'
      SubscriptionStatus.create(subscription: subscription_model, status: 'terminated', stripe_event: se)
    when 'customer.subscription.deleted'
      SubscriptionStatus.create(subscription: subscription_model, status: 'terminated', stripe_event: se)
    else
      puts "Unhandled event type: #{event.type}"
    end


    render json: { message: :success }
  end


  private

  def endpoint_secret
    (Rails.application.credentials.dig(:stripe, :signing_secret) || []).first
  end
end


# require 'sinatra'
# require 'json'
# require 'stripe'
# require 'logger'
# require 'sqlite3'
#
# # Set your Stripe API key
# Stripe.api_key = 'sk_test_YOUR_SECRET_KEY'
#
# # Logger for debugging
# logger = Logger.new(STDOUT)
#
# # Initialize SQLite database
# DB = SQLite3::Database.new 'subscriptions.db'
# DB.execute <<-SQL
#   CREATE TABLE IF NOT EXISTS subscriptions (
#     id TEXT PRIMARY KEY,
#     customer_id TEXT,
#     status TEXT,
#     plan_id TEXT,
#     start_date TEXT,
#     current_period_end TEXT
#   );
# SQL
#
# post '/webhook' do
#   payload = request.body.read
#   event = nil
#
#   begin
#     event = Stripe::Event.construct_from(JSON.parse(payload, symbolize_names: true))
#   rescue JSON::ParserError => e
#     status 400
#     return "Webhook error while parsing: #{e.message}"
#   end
#
#   case event.type
#   when 'checkout.session.completed'
#     handle_checkout_session_completed(event.data.object)
#   when 'customer.subscription.created'
#     handle_subscription_created(event.data.object)
#   when 'customer.subscription.updated'
#     handle_subscription_updated(event.data.object)
#   when 'customer.subscription.deleted'
#     handle_subscription_deleted(event.data.object)
#   when 'invoice.payment_succeeded'
#     handle_payment_succeeded(event.data.object)
#   when 'invoice.payment_failed'
#     handle_payment_failed(event.data.object)
#   when 'customer.subscription.trial_will_end'
#     handle_trial_will_end(event.data.object)
#   when 'charge.dispute.created'
#     handle_dispute_created(event.data.object)
#   when 'charge.refunded'
#     handle_charge_refunded(event.data.object)
#   else
#     logger.info "Unhandled event type: #{event.type}"
#   end
#
#   status 200
# end
#
# def handle_checkout_session_completed(session)
#   logger.info "Checkout session completed: #{session.id} for customer #{session.customer}"
#   # Fetch subscription details using the session
#   if session.subscription
#     subscription = Stripe::Subscription.retrieve(session.subscription)
#     handle_subscription_created(subscription)
#   end
# end
#
# def handle_subscription_created(subscription)
#   logger.info "Subscription created: #{subscription.id} for customer #{subscription.customer}"
#
#   DB.execute("INSERT INTO subscriptions (id, customer_id, status, plan_id, start_date, current_period_end) VALUES (?, ?, ?, ?, ?, ?)",
#              [subscription.id, subscription.customer, subscription.status, subscription.items.data[0].plan.id, Time.at(subscription.start_date).to_s, Time.at(subscription.current_period_end).to_s])
# end
#
# def handle_subscription_updated(subscription)
#   logger.info "Subscription updated: #{subscription.id}"
#
#   DB.execute("UPDATE subscriptions SET status = ?, current_period_end = ? WHERE id = ?",
#              [subscription.status, Time.at(subscription.current_period_end).to_s, subscription.id])
# end
#
# def handle_subscription_deleted(subscription)
#   logger.info "Subscription deleted: #{subscription.id}"
#
#   DB.execute("DELETE FROM subscriptions WHERE id = ?", [subscription.id])
# end
#
# def handle_payment_succeeded(invoice)
#   logger.info "Payment succeeded for invoice: #{invoice.id}"
#   # Grant access or mark invoice as paid in the database
# end
#
# def handle_payment_failed(invoice)
#   logger.info "Payment failed for invoice: #{invoice.id}"
#   # Notify user to update payment method
# end
#
# def handle_trial_will_end(subscription)
#   logger.info "Trial ending soon for subscription: #{subscription.id}"
#   # Send reminder email to user
# end
#
# def handle_dispute_created(dispute)
#   logger.info "Dispute created: #{dispute.id} for charge #{dispute.charge}"
#   # Notify admin and collect evidence
# end
#
# def handle_charge_refunded(charge)
#   logger.info "Charge refunded: #{charge.id}"
#   # Adjust user account balance or notify user
# end
#
# # Start Sinatra server if the script is run directly
# run! if __FILE__ == $0

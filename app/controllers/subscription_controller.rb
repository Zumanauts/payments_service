class SubscriptionController < ApplicationController

  skip_before_action :verify_authenticity_token

  def create

    puts request.query_parameters

    redirect_to "https://buy.stripe.com/7sIdTBc4IcL9eis3cc?client_reference_id=#{0}", allow_other_host: true
  end

  def confirm

    puts request.query_parameters

    redirect_to "https://tabulera.com/checkout-success", allow_other_host: true
  end
end

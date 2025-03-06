class SubscriptionController < ApplicationController
  def create

    puts params

    redirect_to "https://buy.stripe.com/7sIdTBc4IcL9eis3cc?client_reference_id=#{0}", allow_other_host: true
  end

  def confirm

    puts params
    # redirect_to "https://tabulera.com/subscription-success-page", allow_other_host: true
    redirect_to "https://tabulera.com/form-success-page", allow_other_host: true
  end
end

class SubscriptionService

  def self.create_subscription(signup_form_data, instance_name, production_mode)

    full_instance_name = instance_name
    subscription_model = nil
    attempts = 0


    loop do
      begin
        subscription_model = Subscription.create(signup_form_data: signup_form_data,
                                                 portal_instance_name: full_instance_name, production_mode: production_mode)
        break;
      rescue ActiveRecord::RecordNotUnique
        full_instance_name = instance_name + '-' + SecureRandom.hex(2)
      end
      attempts += 1
      raise "Failed to generate uniq domain" if attempts > 10
    end

    subscription_model

  end



  def self.generate_portal_instance_name(company_name, production_mode)

    server_name_suffixes = %w(alfa bravo delta echo golf kilo lima mike romeo).shuffle


    company_name_normalized = company_name.gsub(/[^0-9a-z]/i, '')

    company_name_components = company_name_normalized.gsub(/[[:upper:]]/, ' \0').gsub('  ', ' ').strip.split(' ')

    if company_name_components.count >= 3
      suggested_name = company_name_components.map {|c|c[0]}.join('').downcase
    else
      suggested_name = company_name_normalized.gsub(' ', '').downcase
    end

    full_suggested_name = suggested_name
    attempts = 0

    loop do
      begin
        dns_resolve_host full_suggested_name, production_mode
        break;
      rescue => e
        puts "Exception: #{e}"
        pp e
        full_suggested_name = suggested_name + '-' + (server_name_suffixes[attempts] || SecureRandom.hex(2))
      end
      attempts += 1
      raise "Failed to generate uniq domain" if attempts > 10
    end


    full_suggested_name
  end



  def self.portal_host(portal_name, production_mode)
    "#{production_mode ? "" : "stage-"}#{portal_name}.tabulera.com"
  end

  def self.dns_resolve_host(portal_name, production_mode)
    host = portal_host portal_name, production_mode
    Resolv.getaddress host
  end



end
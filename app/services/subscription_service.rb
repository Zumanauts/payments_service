class SubscriptionService

  def self.create_subscription(subscription_params, company_name, production_mode)

    subscription_model = nil
    server_name_suffixes = %w(alfa bravo delta echo golf kilo lima mike romeo).shuffle

    #Building base server name
    company_name_normalized = company_name.gsub(/[^0-9a-z]/i, '')
    company_name_components = company_name_normalized.gsub(/[[:upper:]]/, ' \0').gsub('  ', ' ').strip.split(' ')

    if company_name_components.count >= 3
      suggested_name = company_name_components.map {|c|c[0]}.join('').downcase
    else
      suggested_name = company_name_normalized.gsub(' ', '').downcase
    end

    full_suggested_name = suggested_name
    attempts = 0

    #Searching available name
    loop do
      if hostname_not_in_use?(full_suggested_name, production_mode)
        begin
          #Name found
          subscription_model = Subscription.create(subscription_params.merge({portal_instance_name: full_suggested_name,
                                                                              production_mode: production_mode}))
          break;
        rescue ActiveRecord::RecordNotUnique
        end
      end

      full_suggested_name = suggested_name + '-' + (server_name_suffixes[attempts] || SecureRandom.hex(2))

      attempts += 1
      raise "Failed to generate uniq domain" if attempts > 12
    end
    
    subscription_model
  end



  def self.portal_host(portal_name, production_mode)
    "#{production_mode ? "" : "stage-"}#{portal_name}.tabulera.com"
  end


  def self.hostname_not_in_use?(portal_name, production_mode)

    begin
      host = portal_host(portal_name, production_mode)
      address = Resolv.getaddress host
      puts "Server name '#{portal_name}' in use at #{address}"

      false
    rescue Resolv::ResolvError
      puts "Found unused name #{portal_name} !"
      true
    end
  end

end
class SubscriptionService

  def self.create_subscription(signup_form_data, company_name, production_mode)

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
      begin
        address = dns_resolve_host full_suggested_name, production_mode
        puts "Server name '#{full_suggested_name}' in use at #{address}"

        full_suggested_name = suggested_name + '-' + (server_name_suffixes[attempts] || SecureRandom.hex(2))

      rescue Resolv::ResolvError
        puts "#{full_suggested_name} !"

        begin
          #Name found
          subscription_model = Subscription.create(signup_form_data: signup_form_data,
                                                   portal_instance_name: full_suggested_name, production_mode: production_mode)
          break;
        rescue ActiveRecord::RecordNotUnique
        end

      end
      attempts += 1
      raise "Failed to generate uniq domain" if attempts > 10
    end


    subscription_model
  end



  def self.portal_host(portal_name, production_mode)
    "#{production_mode ? "" : "stage-"}#{portal_name}.tabulera.com"
  end

  def self.dns_resolve_host(portal_name, production_mode)
    host = portal_host portal_name, production_mode
    Resolv.getaddress host
  end



end
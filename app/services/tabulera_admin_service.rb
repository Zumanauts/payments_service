class TabuleraAdminService

  ADMIN_SERVICE_HOST        = 'http://admin.prod'
  ADMIN_SERVICE_LOGIN_PATH  = '/api/auth/login'
  ADMIN_SERVICE_PING_PATH   = '/api/ping'
  ADMIN_SERVICE_CREATE_PATH = '/api/client_create'


  def initialize(user_name, password)
    authenticate(user_name, password)
  end


  def self.from_config
    TabuleraAdminService.new('payments_service', '0e5d7238503206d9cb61975b2df23e95b99de842be5f1497330ed529f68dd24e')
  end


  # r = t.create_portal_instance 'test', {'First Name':'Doug','Last Name':'Devlin','Email':'andrey.brych@tabulera.com','Confirm Email':'andrey.brych@tabulera.com','Company Legal Name':'Tabulera','EIN':'123456','Company Address':'6200 Stoneridge Mall Rd.','State':'California','Postal Code':'94588'}

  def create_portal_instance server_name, params

    create_url = build_url ADMIN_SERVICE_CREATE_PATH

    payload =  {
        'name': server_name,
        'env': 'Prod',
        'mode': {
            'SelfSet': params
        }
    }

    res = Net::HTTP.post(create_url, payload.to_json, get_headers)

    raise "Failed to create new server" if res.code != '200'

    puts "Requested server start, response code: #{res.code}"


    res

  end


  def ping

    ping_url = build_url ADMIN_SERVICE_PING_PATH

    res = Net::HTTP.get_response(ping_url, get_headers)
  end


  private

  def authenticate(user_name, encrypted_password)
    login_url = build_url ADMIN_SERVICE_LOGIN_PATH

    payload =  {
        'username': user_name,
        'encrypted_password': encrypted_password
    }

    res = Net::HTTP.post(
        login_url,
        payload.to_json,
        "Content-Type" => "application/json"
    )

    json = JSON.parse(res.body)

    @auth_token = json['token']
    puts "Auth token received: #{@auth_token[0..3]}..."

  end

  def build_url(path)
    admin_host_url = ADMIN_SERVICE_HOST

    raise "Error env ADMIN_SERVICE_HOST url is empty" if admin_host_url.nil?

    URI.join(admin_host_url, path)
  end


  def get_headers
    raise "Not authenticated" if @auth_token.nil?

    {
        "Content-Type" => "application/json",
        'Authorization' => "Bearer #{@auth_token}"
    }
  end


end
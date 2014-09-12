class Eloqua < Service
  validates_presence_of :site_name
  validates_presence_of :username, :password
  validates_presence_of :app_client_id, :app_client_secret

  def init
    self.name ||= 'Eloqua'
    self.auth_type ||= 'oauth2'
    self.auth_domain ||= 'https://login.eloqua.com'
    self.auth_path ||= '/auth/oauth2/authorize'
    self.token_path ||= '/auth/oauth2/token'

    #self.api_domain ||= ''
    #self.api_path ||= ''
    #self.discover_path ||= '/contact/fields'
    #self.lead_path ||= ''
    self.request_parameters ||= load_parameters_file.to_json

    #     https://awesomeapp.example.com/create/instance={InstanceId}&asset={AssetId}&site={SiteName}
    #     http://localhost:3000/create/installId={InstallId}&appId={AppId}&callbackurl=http://localhost:3000/oauth/eloqua
  end

  def self.model_name
    Service.model_name
  end

  def app_client_id=(value)
    write_attribute(:app_api_key, value)
  end

  def app_client_secret=(value)
    write_attribute(:app_api_secret, value)
  end

  def app_client_id
    self.app_api_key
  end

  def app_client_secret
    self.app_api_secret
  end

  def authenticate
    check_required_attributes(attrs_for_auth_action)
    auth_params = {
      'grant_type' => 'password',
      'scope' => 'full',
      'username' => self.site_name + "\\" + self.username,
      'password' => self.password
    }

    response_body = make_api_call(self.token_address, 'post', auth_params.to_json)
    return nil unless response_body


    response = EloquaParty.get(token_address)
    return unless is_valid_response(response)

    self.update_attributes!(response)
    self.update_attribute(:auth_error, '')
  end

  def auth_status
    check_required_attributes(attrs_for_auth_status)

    if !self.auth_error.blank?
      return "Authentication Failed (" + self.auth_error + ")"
    elsif is_token_expired
      return "Authentication Token Expired"
    else
      return "Authenticated"
    end
  end

  def lead_address
    self.api_domain + self.lead_path
  end

  def discovery_address
    self.api_domain + self.discover_path
  end

  def get_discovery
    discovery_fields = make_api_call(self.discovery_address, 'get')
    return unless discovery_fields

    discovery_fields['result'].map { |f|
      {
        name: f['rest']['name'],
        display_name: f['displayName'],
        data_type: f['dataType'],
        is_read_only: f['rest']['readOnly']
      }
    }
  end

  # TODO: decouple (model dependencies)
  def sync(definition, sync_operation)
    input_param = self.build_api_input(definition.mappings, sync_operation.source_data)
    request_body = Hash[definition.request_parameters.map {|param|
      [param.name, param.value] unless param.value.blank?
    }.compact!]
    request_body = request_body.merge("input" => input_param)

    response_body = make_api_call(self.lead_address, 'post', request_body.to_json)
    return nil unless response_body

    response_object = response_body.parsed_response
    success_count = nil
    rejects_count = nil

    if response_object['success'] == true
      all_results = response_body['result']
      success_count = all_results.select{|r| r['errors'].blank? }.count
      rejects_count = all_results.count - success_count
    end

    return {
      assigned_service_id: response_object['requestId'],
      request: request_body,
      response: response_object,
      success_count: success_count,
      reject_count: rejects_count
    }
  end

  def build_api_input(mappings, source_data)
    source_data.map do |record|
      Hash[mappings.map {|mapping|
        if mapping.destination_field
          record_key = mapping.source_header.parameterize.underscore.to_sym
          [mapping.destination_field.name, record[record_key].to_s]
        end
      }.compact!]
    end
  end

  private

  def make_api_call(address, type, data=nil)
    response = nil
    headers = {
      'Authorization' => 'Bearer ' + self.access_token,
      'Content-Type' => 'application/json'
    }
    basic_auth = {username: self.app_client_id, password: self.app_client_secret}
    headers.merge('Content-Length' => data.size.to_s) if data

    if type.downcase.underscore == 'get'
      response = MarketoParty.send(type.to_sym, address, headers: headers, basic_auth: basic_auth)
    elsif type == 'post'
      response = MarketoParty.send(type.to_sym, address, headers: headers, body: data.to_s, basic_auth: basic_auth)
    else
      raise 'Marketo only GET and POST actions at this time.' and return
    end

    return response unless response['success'] == false

    if !response['errors'].detect{|error| error['code'] == '602'}.blank?
      self.authenticate
      make_api_call(address, type, data)
    elsif !response['errors'].detect{|error| error['code'] == '601'}.blank?
      message = 'Client keys and/or secret is invalid'
      errors.add(:base, message )
      self.update_attribute(:auth_error, message)
      return nil
    else
      raise 'API ERROR: ' + response['errors'].to_s
    end
  end

  def attrs_for_auth_action
    [:site_name, :username, :password, :app_client_id, :app_client_secret]
  end

  def attrs_for_auth_status
    [:updated_at, :expires_in]
  end

  def token_address
    self.auth_domain + self.token_path
  end

  def is_valid_response(response)
    response_error = response['error_description']
    if response_error
      self.update_attribute(:auth_error, response_error)
      errors.add(:base, response_error) and return false
    else
      true
    end
  end

  def check_required_attributes(attrs)
    blank_attrs = attrs.select{|attr| self.send(attr).blank?}
    error_message = "The following attribute(s) is/are not defined: " + blank_attrs.to_s
    raise error_message unless blank_attrs.blank?
  end

  def is_token_expired
    expires_at = self.updated_at + self.expires_in.seconds
    Time.now > expires_at
  end

  def oauth_client
    OAuth2::Client.new(
      ENV['ELOQUA_CLIENT_ID'],
      ENV['ELOQUA_CLIENT_SECRET'],
      site: self.auth_domain
    )
  end
end


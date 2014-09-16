class Eloqua < Service
  validates_presence_of :app_client_id, :app_client_secret
  before_save :get_api_data

  def init
    self.name ||= 'Eloqua'
    self.auth_type ||= 'oauth2'
    self.auth_domain ||= 'https://login.eloqua.com'
    self.auth_path ||= '/auth/oauth2/authorize'
    self.token_path ||= '/auth/oauth2/token'
    self.app_client_id ||= Rails.application.secrets.eloqua_client_id
    self.app_client_secret ||= Rails.application.secrets.eloqua_client_secret
    self.api_path ||= '/API/Bulk/2.0/'
    self.discover_path ||= '/contacts/fields'
    self.lead_path ||= '/contacts/imports'
    self.request_parameters ||= load_parameters_file.to_json
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

  def auth_address(domain)
    self.auth_domain + self.auth_path +
      '?response_type=code'  +
      '&client_id=' + self.app_client_id +
      '&redirect_uri=' + self.class.redirect_address(domain)  +
      '&scope=full' +
      '&state=Eloqua'
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

  def oauth_client
    OAuth2::Client.new(
      self.app_client_id,
      self.app_client_secret,
      site: self.auth_domain,
      authorize_url: self.auth_path,
      token_url: self.token_path
    )
  end

  def authenticate(request, code)
    check_required_attributes(attrs_for_auth_action)
    client = self.oauth_client
    basic_auth = Base64.urlsafe_encode64(self.app_client_id + ':' + self.app_client_secret)

    begin
      response = client.auth_code.get_token(code,
        redirect_uri: self.class.redirect_address(request),
        headers: { 'Authorization' => 'Basic ' + basic_auth.to_s }
      )
    rescue OAuth2::Error => error
      self.auth_error = error.to_s and return
    end

    self.assign_attributes({
      access_token: response.token,
      refresh_token: response.refresh_token,
      expires_in: response.expires_in,
      auth_error: ''
    })
  end

  private

  def make_api_call(address, type, data=nil)
    response = nil
    headers = {
      'Authorization' => 'Bearer ' + self.access_token,
      'Content-Type' => 'application/json'
    }
    headers.merge('Content-Length' => data.size.to_s) if data

    if type.downcase.underscore == 'get'
      response = EloquaParty.send(type.to_sym, address, headers: headers)
    elsif type == 'post'
      response = EloquaParty.send(type.to_sym, address, headers: headers, body: data.to_s)
    else
      raise 'Eloqua only GET and POST actions at this time.'
    end

    return response #unless response['status'] == 'error'

    # not sure how to handle errors yet because we are not sure what they look like
=begin
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
=end
  end

  def attrs_for_auth_action
    [:app_client_id, :app_client_secret]
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

  def get_api_data
    response = make_api_call(self.auth_domain + '/id', 'get')
    self.assign_attributes({
      api_domain: response['urls']['base']
    })
  end
end


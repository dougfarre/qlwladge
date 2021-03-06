class Marketo < Service
  validates_presence_of :custom_domain
  validates_presence_of :custom_client_id, :custom_client_secret

  def init
    self.name ||= 'Marketo'
    self.auth_type ||= 'oauth'
    self.api_path ||= '/rest'
    self.auth_path ||= '/identity'
    self.token_path ||= '/identity/oauth/token'
    self.discover_path ||= '/v1/leads/describe.json'
    self.lead_path ||= '/v1/leads.json'
    self.request_parameters ||= load_parameters_file.to_json
  end

  def self.model_name
    Service.model_name
  end

  def custom_domain=(value)
    write_attribute(:auth_domain, value)
    write_attribute(:api_domain, value + self.api_path)
  end

  def custom_client_id=(value)
    write_attribute(:app_api_key, value)
  end

  def custom_client_secret=(value)
    write_attribute(:app_api_secret, value)
  end

  def custom_domain
    self.auth_domain
  end

  def custom_client_id
    self.app_api_key
  end

  def custom_client_secret
    self.app_api_secret
  end

  def authenticate
    check_required_attributes(attrs_for_auth_action)
    response = MarketoParty.get(token_address)
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
    input_param = sync_operation.mapped_data.map do |row|
      Service.excluded_meta_attrs.each{|attr| row.delete(attr)}
      row
    end

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
      success_count = all_results.select{|r| !r['id'].blank? }.count
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

  def map_data(mappings, source_data)
    source_data.map.with_index do |record, i|
      Hash[mappings.map {|mapping|
        if mapping.destination_field
          record_key = mapping.source_header.parameterize.underscore.to_sym
          [mapping.destination_field.name, record[record_key].to_s]
        end
      }.compact!].merge({
        'tmp_id' => i + 1,
        'assigned_entity_id' => '',
        'sync_status' => 'new',
        'sync_details' => ''
      })
    end
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
      response = MarketoParty.send(type.to_sym, address, headers: headers)
    elsif type == 'post'
      response = MarketoParty.send(type.to_sym, address, headers: headers, body: data.to_s )
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
    [:custom_domain, :custom_client_id, :custom_client_secret]
  end

  def attrs_for_auth_status
    [:updated_at, :expires_in]
  end

  def token_address
    token_address = self.auth_domain + self.token_path
    token_params = "?grant_type=client_credentials" +
      "&client_id=" + self.custom_client_id +
      "&client_secret=" + self.custom_client_secret
    token_address + token_params
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
end


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
    self.api_path ||= '/API/Bulk/2.0'
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
    self.api_domain + self.discover_path + '?page=100&pageSize=20'
  end

  def auth_address
    self.auth_domain + self.auth_path +
      '?response_type=code'  +
      '&client_id=' + self.app_client_id +
      '&redirect_uri=' + self.class.redirect_address(self.current_request)  +
      '&scope=full' +
      '&state=Eloqua'
  end

  def get_discovery
    discovery_fields = make_api_call(self.discovery_address, 'get')

    discovery_fields['items'].map { |f|
      {
        display_name: f['name'],
        name: f['internalName'],
        data_type: f['dataType'],
        is_read_only: f['hasReadOnlyConstraint'],
        allows_null: !f['hasNotNullConstraint'],
        is_required: f['hasNotNullConstraint'],
        allows_duplicate: !f['hasUniquenessConstraint'],
        statement: f['statement'],
        uri: f['uri']
      }
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

  # TODO: decouple (model dependencies)
  def sync(definition, sync_operation)
    export_address = self.api_domain + sync_operation.assigned_service_id + '/data'
    request_body = sync_operation.mapped_data.map do |row|
      Service.excluded_meta_attrs.each{|attr| row.delete(attr)}
      row
    end
    response_body = make_api_call(export_address, 'post', request_body.to_json)
    return nil unless response_body

    response_object = response_body.parsed_response

    return {
      request: request_body,
      response: response_object,
      assigned_sync_id: response_object['syncedInstanceUrl'],
      pending_count: sync_operation.mapped_data.count
    }
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

  def authenticate
    self.reauthenticate and return if self.refresh_token
    check_required_attributes(attrs_for_auth_action)
    auth_call(false)
  end

  def reauthenticate
    check_required_attributes(attrs_for_reauth_action)
    auth_call(true)
  end

  def export_params(mappings, sync_operation)
    export_definition = {
      "name" => sync_operation.definition.description,
      "fields" => new_export_fields(mappings),
      "identifierFieldName" => sync_operation.unique_header,
      "isSyncTriggeredOnImport" => "true"
    }

    response = make_api_call(lead_address, 'post', export_definition.to_json)
    binding.pry
    { assigned_service_id: response['uri'], name: response['name'] }
  end

  private

  def new_export_fields(mappings)
    Hash[mappings.select{|mapping| !mapping.destination_field.blank?}.map{|mapping|
      [mapping.destination_field.name, mapping.destination_field.statement]
    }]
  end

  def auth_call(is_reauth)
    client = self.oauth_client
    basic_auth = Base64.urlsafe_encode64(self.app_client_id + ':' + self.app_client_secret)
    token_params = {
      redirect_uri: self.class.redirect_address(self.current_request),
      headers: { 'Authorization' => 'Basic ' + basic_auth.to_s }
    }
    token_params.merge!({
      'grant_type' => 'refresh_token', 
      'scope' => 'full',
      'refresh_token' => self.refresh_token
    }) if is_reauth

    begin
      response = client.auth_code.get_token(self.access_code, token_params)
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

  def make_api_call(address, type, data=nil)
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

    if response === 'Not authenticated.'
      self.auth_error = response.to_s
      self.reauthenticate
      make_api_call(address, type, data)
    end

    response
  end

  def attrs_for_auth_action
    [:app_client_id, :app_client_secret, :access_code, :current_request]
  end

  def attrs_for_reauth_action
    [:app_client_id, :app_client_secret, :refresh_token, :current_request]
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
    return unless new_record?
    response = make_api_call(self.auth_domain + '/id', 'get')
    self.assign_attributes({
      api_domain: response['urls']['base'] + self.api_path
    })
  end
end


require 'open3'

class VendHQ < Service
  validates_presence_of :app_id, :app_secret
  validate :validate_metrc_credentials, on: :update

  def init
    self.name ||= 'VendHQ'
    self.auth_type ||= 'oauth2'
    self.api_path ||= '/api'
    self.auth_domain ||= 'https://secure.vendhq.com'
    self.auth_path ||= '/connect'
    self.token_path ||= '/api/1.0/token'
    self.app_id ||= Rails.application.secrets.vendhq_app_id
    self.app_secret ||= Rails.application.secrets.vendhq_app_secret
    self.request_parameters ||= load_parameters_file.to_json
  end

  def validate_metrc_credentials
    auth_status = self.auth_status == "Authenticated" rescue false
    if !new_record? and auth_status
      errors.add(:metrc_username, 'cannot be blank') if self.metrc_username.blank?
      errors.add(:metrc_password, 'cannot be blank') if self.metrc_password.blank?
    end
  end

  def self.model_name
    Service.model_name
  end

  def app_id=(value)
    write_attribute(:app_api_key, value)
  end

  def app_secret=(value)
    write_attribute(:app_api_secret, value)
  end

  def app_id
    self.app_api_key
  end

  def app_secret
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

  def suppliers_address
    self.api_domain + '/api/supplier'
  end

  def products_address
    self.api_domain + '/api/products?active=1'
  end

  def auth_address
    self.auth_domain + self.auth_path +
      '?response_type=code'  +
      '&client_id=' + self.app_id +
      '&redirect_uri=' + self.class.redirect_address(self.current_request)
  end

  def generic_call(path)
    path_array = path.split('/')
    entity = path_array[path_array.length - 1]
    make_api_call(self.api_domain + path, 'get')[entity]
  end

  def get_products
    response = make_api_call(self.products_address, 'get')
    products = response['products']
    pagination = response['pagination']
    return products unless pagination

    (2..pagination['pages'].to_i).each{|i|
      next_products = make_api_call(self.products_address + '&page=' + i.to_s, 'get')
      products.concat(next_products['products'])
    }

    products
  end

  def get_suppliers
    response = make_api_call(self.suppliers_address, 'get')
    suppliers = response['suppliers']
    pagination = response['pagination']
    return suppliers unless pagination

    (2..pagination['pages'].to_i).each{|i|
      next_suppliers = make_api_call(self.suppliers_address + '?page=' + i.to_s, 'get')
      suppliers.concat(next_suppliers['suppliers'])
    }

    suppliers
  end

  def get_product_groups
    suppliers = self.get_suppliers.map{|gi|
      gi.merge({'type' => 'Supplier', 'measurement' => 'Units'})
    }

    products = self.get_products.map{|gi|
      gi.merge({'measurement' => 'Grams'})
    }.select{|gi|
      gi['type'] == 'Cannabis'
    }

    binding.pry
    (suppliers + products).map {|f| {
      name: f['name'],
      id: f['id'],
      type: f['type'],
      measurement: f['measurement']
    }}
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

  def oauth_client(get_token=false)
    OAuth2::Client.new(
      self.app_id,
      self.app_secret,
      site: get_token ? self.api_domain : self.auth_domain,
      authorize_url: self.auth_path,
      token_url: self.token_path
    )
  end

  def authenticate
    if !self.access_token.blank?
      self.reauthenticate
    else
      return true unless self.new_record?
      check_required_attributes(attrs_for_auth_action)
      auth_call(false)
    end
  end

  def reauthenticate
    check_required_attributes(attrs_for_reauth_action)
    auth_call(true)
  end

  def metrc_facilities
    error_message = "Metrc credentials invalid or the service is offline."
    cmd = Rails.root.to_s + '/product_report/node_modules/casperjs/bin/casperjs'
    cmd << ' ' + Rails.root.to_s + '/product_report/facility_scraper.js'
    cmd << ' ' + '--username="' + self.metrc_username + '"'
    cmd << ' ' + '--password="' + self.metrc_password + '"'

    Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
      response = JSON.parse(stdout.read.delete!("\n"))
      return response unless response[0] == 'error'
    end

    self.update_attribute(:auth_error, error_message)
  end

  def metrc_packages(facility)
    error_message = "Metrc credentials invalid or the service is offline."
    cmd = Rails.root.to_s + '/product_report/node_modules/casperjs/bin/casperjs'
    cmd << ' ' + Rails.root.to_s + '/product_report/package_scraper.js'
    cmd << ' ' + '--username="' + self.metrc_username + '"'
    cmd << ' ' + '--password="' + self.metrc_password + '"'
    cmd << ' ' + '--facility="' + facility + '"'

    Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
      response = JSON.parse(stdout.read.delete!("\n"))
      return response['Data'] unless response[0] == 'error'
    end

    self.update_attribute(:auth_error, error_message)
  end

  private

  def auth_call(is_reauth)
    client = self.oauth_client(true)
    token_params = {
      'redirect_uri' => self.class.redirect_address(self.current_request),
      'client_id' => self.app_id,
      'client_secret' => self.app_secret
    }
    token_params.merge!({
      'grant_type' => 'refresh_token',
      'refresh_token' => self.refresh_token,
    }) if is_reauth
    token_params.delete('redirect_uri') if is_reauth
    begin

      response = client.auth_code.get_token(self.access_code, token_params)
    rescue OAuth2::Error => error
      self.auth_error = error.to_s and return
    end

    response.refresh_token = self.refresh_token unless response.refresh_token

    self.assign_attributes({
      access_token: response.token,
      refresh_token: response.refresh_token,
      expires_in: response.expires_in,
      facilities: [],
      auth_error: ''
    })

    if !self.metrc_username.blank? and !self.metrc_password.blank?
      self.facilities = self.metrc_facilities
    end

    return self.valid?
  end

  def make_api_call(address, type, data=nil)
    headers = {
      'Authorization' => 'Bearer ' + self.access_token,
      'Content-Type' => 'application/json'
    }
    headers.merge('Content-Length' => data.size.to_s) if data

    if type.downcase.underscore == 'get'
      response = VendHQParty.send(type.to_sym, address, headers: headers)
    elsif type == 'post'
      response = VendHQParty.send(type.to_sym, address, headers: headers, body: data.to_s)
    else
      raise 'VendHQ only GET and POST actions at this time.'
    end

    if response === 'Not authenticated.'
      self.auth_error = response.to_s
      self.reauthenticate
      make_api_call(address, type, data)
    end

    response
  end

  def attrs_for_auth_action
    [:app_id, :app_secret, :access_code, :current_request]
  end

  def attrs_for_reauth_action
    [:app_id, :app_secret, :refresh_token, :current_request]
  end

  def attrs_for_auth_status
    [:updated_at, :expires_in]
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

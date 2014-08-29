class Marketo < Service
  validates_presence_of :custom_domain
  validates_presence_of :custom_client_id, :custom_client_secret

  def init
    self.name ||= 'Marketo'
    self.auth_type ||= 'oauth2'
    self.api_path ||= '/rest'
    self.auth_path ||= '/identity'
    self.token_path ||= '/identity/oauth/token'
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

  def get_access_token
    check_required_attributes(user_defined_attrs_for_authenticate)
    response = MarketoParty.get(token_address)
    check_response_object(response)
    self.update_attributes(response)
  end

  def refresh_access_token

  end
  private

  def auth_token=(value)
    super
  end

  def check_required_attributes(attrs)
    blank_attrs = attrs.select{|attr| self.send(attr).blank?}
    error_message = "The following attribute(s) is/are not defined: " + blank_attrs.to_s
    raise error_message unless blank_attrs.blank?
  end

  def user_defined_attrs_for_authenticate
    [:custom_domain, :custom_client_id, :custom_client_secret]
  end

  def token_address
    token_address = self.auth_domain + self.token_path
    token_params = "?grant_type=client_credentials" +
      "&client_id=" + self.custom_client_id +
      "&client_secret=" + self.custom_client_secret
    token_address + token_params
  end

  def check_response_object(response)
    raise response[:error_description] if response[:error_description]
  end
end


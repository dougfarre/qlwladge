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
    write_attribute(:api_domain, value)
  end

  def custom_domain
    auth_domain
  end

  def custom_client_id=(value)
    write_attribute(:app_api_key, value)
  end

  def custom_client_secret=(value)
    write_attribute(:app_api_secret, value)
  end

  def custom_client_id
    app_api_key
  end

  def custom_client_secret
    app_api_secret
  end
end


class Marketo < Service
  #after_initialize :init
  alias_attribute :custom_client_id, :application_api_key
  alias_attribute :custom_client_secret, :application_api_secret

  def init
    self.name ||= 'Marketo'
    self.auth_type ||= 'oauth2'
    self.api_path ||= '/rest'
    self.authorization_path ||= '/identity/oauth/token'
  end

  def self.model_name
    Service.model_name
  end

  def custom_domain=(value)
    uri = URI.parse(value)

    if uri.kind_of?(URI::HTTP) or uri.kind_of?(URI::HTTPS)
      self.authorization_domain = value
      self.api_domain = value
    else
      errors.add(:host, "Host url is not valid.")
    end
  end
end


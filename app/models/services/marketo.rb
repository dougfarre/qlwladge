class Marketo < Service
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
      write_attribute(:authorization_domain, uri.to_s)
      write_attribute(:api_domain, uri.to_s)
    else
      errors.add(:host, "Host url is not valid.")
    end
  end
end


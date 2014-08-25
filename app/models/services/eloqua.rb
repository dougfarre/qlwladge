class Eloqua < Service
  after_initialize :init

  def init
    self.name ||= 'Eloqua'
    self.auth_type ||= 'oauth2'
    self.auth_path ||= '/auth/oauth2/authorize'
  end

  def self.model_name
    Service.model_name
  end
end

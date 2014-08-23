class Eloqua < Service
  after_initialize :init

  def init
    self.name ||= 'Eloqua'
    self.auth_type ||= 'oauth2'
    self.authorization_path ||= '/auth/oauth2/authorize'
    self.token_path ||= '/auth/oauth2/token'
  end
end

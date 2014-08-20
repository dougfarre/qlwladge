# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

# Services
ServiceType.create([
  {
    name: 'Eloqua',
    auth_type: 'oauth2',
    authorize_path: '/auth/oauth2/authorize',
    token_path: '/auth/oauth2/token'
  },
  {
    name: 'Marketo',
    auth_type: 'oauth2',
    authorize_path: '',
    token_path: '/identity/oauth/token'
  }
])

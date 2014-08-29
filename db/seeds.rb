# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

# User
user = User.new(
    email: 'doug@locksport.com',
    password: 'password',
    password_confirmation: 'password'
)
user.save!

# Services

user.services << Eloqua.create()
user.services << Marketo.create()
user.save

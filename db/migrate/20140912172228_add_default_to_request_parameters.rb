class AddDefaultToRequestParameters < ActiveRecord::Migration
  def change
    add_column :request_parameters, :default, :string
  end
end

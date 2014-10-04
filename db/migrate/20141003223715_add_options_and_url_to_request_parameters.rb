class AddOptionsAndUrlToRequestParameters < ActiveRecord::Migration
  def change
    add_column :request_parameters, :options, :text
    add_column :request_parameters, :options_type, :string
    add_column :request_parameters, :url, :string
  end
end

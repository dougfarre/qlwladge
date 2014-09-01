class CreateRequestParameters < ActiveRecord::Migration
  def change
    create_table :request_parameters do |t|
      t.integer :definition_id
      t.string :definition
      t.string :name
      t.string :value
      t.boolean :optional

      t.timestamps
    end
  end
end

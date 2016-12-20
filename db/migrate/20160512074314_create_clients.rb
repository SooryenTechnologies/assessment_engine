class CreateClients < ActiveRecord::Migration
  def change
    create_table :clients do |t|
      t.string :client_name
      t.text :api_key
      t.text :secret_key

      t.timestamps
    end
  end
end

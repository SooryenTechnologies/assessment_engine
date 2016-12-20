class AddEmailToClients < ActiveRecord::Migration
  def change
    add_column :clients, :email, :string
    add_column :clients, :password, :string
  end
end

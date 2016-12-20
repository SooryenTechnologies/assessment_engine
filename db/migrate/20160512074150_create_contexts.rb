class CreateContexts < ActiveRecord::Migration
  def change
    create_table :contexts do |t|
      t.string :context
      t.text :description
      t.integer :created_by
      t.integer :updated_by

      t.timestamps
    end
  end
end

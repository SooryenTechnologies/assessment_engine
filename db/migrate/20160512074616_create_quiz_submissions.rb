class CreateQuizSubmissions < ActiveRecord::Migration
  def change
    create_table :quiz_submissions do |t|
      t.integer :quiz_id
      t.integer :user_id
      t.integer :created_by
      t.integer :updated_by

      t.timestamps
    end
  end
end

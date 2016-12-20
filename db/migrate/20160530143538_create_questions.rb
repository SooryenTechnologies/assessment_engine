class CreateQuestions < ActiveRecord::Migration
  def change
    create_table :questions do |t|
      t.text :name
      t.integer :migration_id
      t.integer :position
      t.timestamp :deleted_at
      t.text :question_data
    end
  end
end

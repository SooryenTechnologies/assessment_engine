class CreateQuizQuestions < ActiveRecord::Migration
  def change
    create_table :quiz_questions do |t|
      t.integer :quiz_id
      t.integer :question_bank_id
      t.integer :question_type_id
      t.text :question_data
      t.string :workflow_state
      t.integer :created_by
      t.integer :updated_by

      t.timestamps
    end
  end
end

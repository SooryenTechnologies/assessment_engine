class CreateQuizzes < ActiveRecord::Migration
  def change
    create_table :quizzes do |t|
      t.string :title
      t.text :description
      t.integer :context_id
      t.decimal :points_possible
      t.string :context_type
      t.string :workflow_state
      t.boolean :shuffle_answers
      t.boolean :show_correct_answers
      t.integer :time_limit
      t.integer :allowed_attempts
      t.string :quiz_type
      t.datetime :lock_at
      t.datetime :unlock_at
      t.boolean :could_be_locked
      t.datetime :due_at
      t.integer :question_count
      t.datetime :published_at
      t.datetime :last_edited_at
      t.integer :created_by
      t.integer :updated_by
      t.string :hide_results
      t.boolean :one_question_at_a_time
      t.datetime :show_correct_answers_at
      t.datetime :hide_correct_answers_at
      t.boolean :one_time_result
      t.boolean :show_correct_answers_after_last_attempt

      t.timestamps
    end
  end
end

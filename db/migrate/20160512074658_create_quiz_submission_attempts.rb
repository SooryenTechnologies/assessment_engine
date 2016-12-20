class CreateQuizSubmissionAttempts < ActiveRecord::Migration
  def change
    create_table :quiz_submission_attempts do |t|
      t.integer :quiz_submission_id
      t.text :submission_data
      t.decimal :score
      t.decimal :kept_score
      t.text :quiz_data
      t.timestamp :started_at
      t.timestamp :end_at
      t.timestamp :finished_at
      t.string :workflow_state
      t.integer :created_by
      t.integer :updated_by
      t.decimal :fudge_points
      t.decimal :quiz_points_possible
      t.integer :extra_time
      t.boolean :manually_unlocked
      t.boolean :manually_scored
      t.boolean :score_before_regrade
      t.boolean :was_preview
      t.boolean :has_seen_results

      t.timestamps
    end
  end
end

class RemoveUnnecessaryColumnsAndTables < ActiveRecord::Migration
  def self.up
    remove_column :contexts, :description
    remove_column :question_banks, :workflow_state
    remove_column :questions, :position
    remove_column :questions, :deleted_at
    remove_column :questions, :migration_id
    remove_column :quiz_questions, :workflow_state
    remove_column :quiz_submission_attempts, :kept_score
    remove_column :quiz_submission_attempts, :quiz_data
    remove_column :quiz_submission_attempts, :workflow_state
    remove_column :quiz_submission_attempts, :fudge_points
    remove_column :quiz_submission_attempts, :quiz_points_possible
    remove_column :quiz_submission_attempts, :extra_time
    remove_column :quiz_submission_attempts, :manually_unlocked
    remove_column :quiz_submission_attempts, :manually_scored
    remove_column :quiz_submission_attempts, :score_before_regrade
    remove_column :quiz_submission_attempts, :has_seen_results
    remove_column :quizzes, :context_type
    remove_column :quizzes, :workflow_state
    remove_column :quizzes, :could_be_locked
    remove_column :quizzes, :one_time_result
    remove_column :quizzes, :show_correct_answers_after_last_attempt
  end

  def self.down
    add_column :contexts, :description
    add_column :question_banks, :workflow_state
    add_column :questions, :position
    add_column :questions, :deleted_at
    add_column :questions, :migration_id
    add_column :quiz_questions, :workflow_state
    add_column :quiz_submission_attempts, :kept_score
    add_column :quiz_submission_attempts, :quiz_data
    add_column :quiz_submission_attempts, :workflow_state
    add_column :quiz_submission_attempts, :fudge_points
    add_column :quiz_submission_attempts, :quiz_points_possible
    add_column :quiz_submission_attempts, :extra_time
    add_column :quiz_submission_attempts, :manually_unlocked
    add_column :quiz_submission_attempts, :manually_scored
    add_column :quiz_submission_attempts, :score_before_regrade
    add_column :quiz_submission_attempts, :has_seen_results
    add_column :quizzes, :context_type
    add_column :quizzes, :workflow_state
    add_column :quizzes, :could_be_locked
    add_column :quizzes, :one_time_result
    add_column :quizzes, :show_correct_answers_after_last_attempt
  end
end

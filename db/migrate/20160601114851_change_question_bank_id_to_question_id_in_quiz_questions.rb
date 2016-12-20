class ChangeQuestionBankIdToQuestionIdInQuizQuestions < ActiveRecord::Migration
  def change
    rename_column :quiz_questions, :question_bank_id, :question_id
  end
end

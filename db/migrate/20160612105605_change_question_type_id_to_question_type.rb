class ChangeQuestionTypeIdToQuestionType < ActiveRecord::Migration
  def change
    remove_column :quiz_questions, :question_type_id
    add_column :quiz_questions, :question_type, :string, after: :question_id
  end
end

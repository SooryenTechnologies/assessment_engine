class AddQuestionBankToQuestions < ActiveRecord::Migration
  def change
    add_reference :questions, :question_bank, index: true
  end
end

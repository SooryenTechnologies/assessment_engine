class CreateQuestionBanks < ActiveRecord::Migration
  def change
    create_table :question_banks do |t|
      t.string :title
      t.integer :user_id
      t.integer :context_id
      t.string :workflow_state
      t.integer :created_by
      t.integer :updated_by

      t.timestamps
    end
  end
end

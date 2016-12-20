class CreateQuestionTypes < ActiveRecord::Migration
  def change
    create_table :question_types do |t|
      t.string :title
      t.string :class_name
      t.integer :created_by
      t.integer :updated_by

      t.timestamps
    end
  end
end

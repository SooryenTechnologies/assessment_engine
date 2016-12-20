# Assessment engine is designed to assess mastery of student learning outcomes. Formative and summative assessments are designed and administered by instructors to be taken by students.
# Copyright (C) 2016 Assessment engine by Sooryen Technologies & Café Learn, inc.
#
# This file is part of Assessment engine.
#
# Assessment engine is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Assessment engine is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#
class QuizQuestion < ActiveRecord::Base
  belongs_to :question
  belongs_to :quiz
  before_save :create_question

  serialize :question_data, Hash
  validates :question_type, :inclusion => { :in => :question_type_options }
  validate :validate_question_data, :on => [ :create, :update ]

  # Add question to the questions table.
  def create_question
    q = self.question || Question.new
    if !self.question.present?
      q.name = "Question"
      q.question_data = self.question_data
      q.context_id = self.quiz.context_id
      q.question_bank_id = QuestionBank.where(context_id: self.quiz.context_id).first.id
      q.save! if q.new_record?
      self.question = q
    end
    return true
  end

  # valid question types
  def question_type_options
    %w[multiple_choice_question true_false_question short_answer_question multiple_answers_question multiple_dropdowns_question matching_question]
  end
  #  Validate question data parameters.
  def validate_question_data
    errors.add(:question_text, "can not be blank.") if !self.question_data[:question_text].present?
    errors.add(:answers, "Please add answer options.") if !self.question_data[:answers].present?
    if (self.question_data[:question_text].present? && self.question_data[:question_text].length < 8)
      errors.add(:question_text, "must have 8 characters.")
    else
      if self.question_data[:question_text].count(" ") == 0
        errors.add(:question_text, "must be in between 8 to 1000 characters long.") if self.question_data[:question_text].length > 1000
      else
        errors.add(:question_text, "must be in between 8 to 1500 characters long.") if self.question_data[:question_text].length > 1500
      end
    end

    if !question_data[:points_possible].present?
      errors.add(:base, "Question points cannot be blank")
    elsif question_data[:points_possible].present?
      points_possible = Integer(question_data[:points_possible]) rescue false
      if (!points_possible.present? || question_data[:points_possible].include?("-") || question_data[:points_possible].include?("+"))
        if question_data[:points_possible].include?(" ")
          errors.add(:base, "Blank space is not allowed in question points")
        else
          errors.add(:base, "Please enter only numeric question points")
        end
      end
    end

    if question_data[:question_type] == "short_answer_question"
      if (!question_data[:question_text].include?("[ ]"))
        errors.add(:base, "Use [ ] with space inside for correct blank answer as shown in example")
      end
    end

    answers = []
    if question_data[:question_type] == "matching_question"
      question_data[:answers].each {|key,str| answers << str}
      answer_present = 0
      answers.each do |i| answer_present = 1+answer_present if(i["left"].present? && i["right"].present?) end
      if answer_present <= 1
        errors.add(:base, "Please fill atleast two matching answers text properly")
      elsif answer_present >= 2
        flag = false
        blank_flag = false
        answers.each do |i|
          if ((!i["left"].present? && i["right"].present?) || (i["left"].present? && !i["right"].present?))
            flag = true
          end
          if (!i["left"].present? && !i["right"].present?)
            blank_flag = true
          end
        end
        if flag == true
          errors.add(:base, "Please fill matching answer properly")
        end
        if blank_flag == true
          errors.add(:base, "Answer text cannot be blank")
        end
      end
    else
      question_data[:answers].each {|key,str| answers << str["text"]}
      answer_text = []
      flag = true
      answers.map{|i| answer_text << i if i != "" }
      question_data[:answers].each {|key,str| puts flag = false if(str["text"] == "" && str["right_or_wrong"] == "true")}
      if answer_text.flatten.length <= 1
        errors.add(:base, "Please submit atleast two answers text")
      elsif flag == false
        errors.add(:base, "Please mark atleast one as a correct answer")
      elsif answers.include?("")
        errors.add(:base, "Answer text cannot be blank")
      end
    end
  end
  # Duplicate the quiz question.
  def self.duplicate_quiz_question(quiz, question_ids, user_id)
    questions_list = []
    Question.transaction do
      questions = []
      question_ids.each do |id|
        question = Question.find id
        questions = quiz.quiz_questions.build(question_id: question.id, question_type: question.question_data[:question_type], :question_data => question.question_data, created_by: user_id, updated_by: user_id)
        questions.save
        questions_list << questions
      end
    end
    return questions_list
  end
end

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
class Quiz < ActiveRecord::Base
  has_many :quiz_questions
  has_many :quiz_submissions

  validates :title, :presence => { :message => "cannot be blank. Please add a title." }, :length => {:within => 8..125}, :format => {with: /\A[a-zA-Z0-9][a-zA-Z0-9 \' ,&-:".?()!\b]*\z/i}
  validates :description, :presence => { :message => "cannot be blank. Please add a instructions." }, :length => {:within => 1..500}, :format => {with: /\A[a-zA-Z0-9][a-zA-Z0-9 \' \s,&-:".?()!\b]*\z/i}
  validates :context_id, presence: true
  validates :resource_link_id, presence: true
  validates :resource_link_id, uniqueness: {scope: :context_id}
  validates :quiz_type, presence: true, :inclusion => { :in => :quiz_type_options }
  validates :time_limit, :presence => { :message => "cannot be blank" }, :if => :time_limit_check?
  validates_numericality_of :time_limit, less_than_or_equal_to: 1500,:only_integer => true, :if => :time_limit_check?
  validate :validate_quiz_dates

  # Allowed role type to perform creation or updation action
  ALLOWED_ROLES = ["Instructor", "Admin"]
  # valid quiz types
  def quiz_type_options
    %w[graded_assessment test_assessment survey]
  end
  # Validate the quiz start date/time and end date/time
  validate do |quiz|
    if show_quiz_response? && show_correct_answers?
      quiz.errors.add(:base, "Correct Answers Start Date cannot be blank") unless quiz.show_correct_answers_at_date?
      quiz.errors.add(:base, "Correct Answers Start time cannot be blank") unless quiz.show_correct_answers_at_time?
      quiz.errors.add(:base, "Correct Answers End Date cannot be blank") unless quiz.hide_correct_answers_at_date?
      quiz.errors.add(:base, "Correct Answers End time cannot be blank") unless quiz.hide_correct_answers_at_time?
    end
    if auto_publish?
      quiz.errors.add(:base, "Available From date cannot be blank") unless quiz.lock_at?
      quiz.errors.add(:base, "Until date cannot be blank") unless quiz.unlock_at?
    end
  end

  # Validation for all types of Start date and End date while creating quiz
  def validate_quiz_dates
    if lock_at && unlock_at
      right_dates = true
      # The today's date is greater than lock date.
      if lock_at < Date.today
        errors.add(:base, "Until date can't be in the past.")
        right_dates = false
      end
      if right_dates
        # The lock_at date is less than unlock_at.
        if lock_at <= unlock_at
          errors.add(:base, "Until date should be greater than the Available From date.")
        end
      end
    end
    # Show/hide the correct answers to the students
    # according to the parameters passed.
    if show_correct_answers_at_date && hide_correct_answers_at_date
      right_dates = true
      if hide_correct_answers_at_date < Date.today
        errors.add(:base, "Correct Answers End Date can't be in the past.")
        right_dates = false
      end
      if right_dates
        if hide_correct_answers_at_date <= show_correct_answers_at_date
          errors.add(:base, "Correct Answers End Date should be greater than Start date.")
        end
      end
    end
  end

  # Create quiz 
  def self.quiz_create(quiz_parameters, context_id, user_id)
    quiz = Quiz.new(quiz_parameters)
    quiz.context_id, quiz.created_by, quiz.updated_by = context_id, user_id, user_id
    if quiz.save
      return {quiz: quiz, total_questions_count: quiz.quiz_questions.count, status: 200}
    else
      return {status: 422, errors: quiz.errors.full_messages}
    end
  end
  # Set quiz form parameters to store that in the database.
  def self.set_quiz_parameters(quiz_parameters)
    boolean_parameter = ["1", "true"]
    quiz_parameters = YAML.load(quiz_parameters.gsub("=>", ":")).symbolize_keys
    quiz_parameters[:time_limit_check] = quiz_parameters[:time_limit_check].present? ? quiz_parameters[:time_limit_check] : nil
    quiz_parameters[:time_limit] = ((boolean_parameter.include? quiz_parameters[:time_limit_check]) && quiz_parameters[:time_limit].present?) ? quiz_parameters[:time_limit] : nil
    quiz_parameters[:allow_multiple_attempt_check] = quiz_parameters[:allow_multiple_attempt_check].present? ? quiz_parameters[:allow_multiple_attempt_check] : nil
    quiz_parameters[:allowed_attempts] = ((boolean_parameter.include? quiz_parameters[:allow_multiple_attempt_check]) && quiz_parameters[:allowed_attempts].present?) ? quiz_parameters[:allowed_attempts] : nil
    quiz_parameters[:score_filter] = ((boolean_parameter.include? quiz_parameters[:allow_multiple_attempt_check]) && quiz_parameters[:score_filter].present?) ? quiz_parameters[:score_filter] : nil
    quiz_parameters[:one_question_at_a_time] = quiz_parameters[:one_question_at_a_time].present? ? quiz_parameters[:one_question_at_a_time] : nil
    quiz_parameters[:lock_question_after_answer] = ((boolean_parameter.include? quiz_parameters[:one_question_at_a_time]) && quiz_parameters[:lock_question_after_answer].present?) ? quiz_parameters[:lock_question_after_answer] : "0"
    quiz_parameters[:show_quiz_response] = quiz_parameters[:show_quiz_response].present? ? quiz_parameters[:show_quiz_response] : nil
    quiz_parameters[:show_correct_answers] = quiz_parameters[:show_correct_answers].present? ? quiz_parameters[:show_correct_answers] : nil
    quiz_parameters[:once_after_each_attempt] = ((boolean_parameter.include? quiz_parameters[:show_quiz_response]) && quiz_parameters[:once_after_each_attempt].present?) ? quiz_parameters[:once_after_each_attempt] : nil
    quiz_parameters[:show_correct_answers_at_date] = ((boolean_parameter.include? quiz_parameters[:show_quiz_response]) && (boolean_parameter.include? quiz_parameters[:show_correct_answers]) && quiz_parameters[:show_correct_answers_at_date].present?) ? Quiz.change_date_format(quiz_parameters[:show_correct_answers_at_date]) : nil
    quiz_parameters[:show_correct_answers_at_time] = ((boolean_parameter.include? quiz_parameters[:show_quiz_response]) && (boolean_parameter.include? quiz_parameters[:show_correct_answers]) && quiz_parameters[:show_correct_answers_at_time].present?) ? quiz_parameters[:show_correct_answers_at_time].to_time : nil
    quiz_parameters[:hide_correct_answers_at_date] = ((boolean_parameter.include? quiz_parameters[:show_quiz_response]) && (boolean_parameter.include? quiz_parameters[:show_correct_answers]) && quiz_parameters[:hide_correct_answers_at_date].present?) ? Quiz.change_date_format(quiz_parameters[:hide_correct_answers_at_date]) : nil
    quiz_parameters[:hide_correct_answers_at_time] = ((boolean_parameter.include? quiz_parameters[:show_quiz_response]) && (boolean_parameter.include? quiz_parameters[:show_correct_answers]) && quiz_parameters[:hide_correct_answers_at_time].present?) ? quiz_parameters[:hide_correct_answers_at_time].to_time : nil
    quiz_parameters[:auto_publish] = quiz_parameters[:auto_publish].present? ? quiz_parameters[:auto_publish] : nil
    quiz_parameters[:lock_at] = ((boolean_parameter.include? quiz_parameters[:auto_publish]) && quiz_parameters[:lock_at].present?) ? Quiz.change_date_format(quiz_parameters[:lock_at]) : nil
    quiz_parameters[:unlock_at] = ((boolean_parameter.include? quiz_parameters[:auto_publish]) && quiz_parameters[:unlock_at].present?) ? Quiz.change_date_format(quiz_parameters[:unlock_at]) : nil
    quiz_parameters[:due_at] = ((boolean_parameter.include? quiz_parameters[:auto_publish]) && quiz_parameters[:due_at].present?) ? Quiz.change_date_format(quiz_parameters[:due_at]) : nil
    quiz_parameters[:published_at] = quiz_parameters[:published_at].present? ? Quiz.change_date_format(quiz_parameters[:published_at]) : nil
    quiz_parameters[:last_edited_at] = DateTime.now
    quiz_parameters[:auto_publish] = quiz_parameters[:auto_publish].present? ? quiz_parameters[:auto_publish] : nil
    return quiz_parameters
  end

  # To get the results for all quizzes which have submitted by students.
  def self.get_result_of_all_quizzes(quizzes)
    result = []
    quizzes.each do |quiz|
      score_array = []
      # Calculate the total score available for the quiz.
      total_marks_possible = quiz.quiz_questions.map{|l| l.question_data[:points_possible].to_f }.sum
      # Calculate the score for each submission.
      quiz.quiz_submissions.each do |submission|
        score_array << { user_id: User.find(submission.user_id).recieved_user_id, attempts: submission.quiz_submission_attempts.select([:id, :score, :started_at, :end_at, :created_by]).map{|l| {id: l.id, score: l.score.to_f, score_in_percentage: (l.score.to_f/total_marks_possible), started_at: l.started_at, end_at: l.end_at}} }
      end
      result << {quiz_id: quiz.resource_link_id, grades: score_array, total_marks_possible: total_marks_possible}
    end
    return result
  end
  
  # Change the date format to store in the db.
  def self.change_date_format(date)
    DateTime.strptime(date,"%m/%d/%Y").to_date
  end
end

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

module Api::V1::QuizSubmission::QuizSubmission
  class QuizSubmissionBuilder

    # Submitting the response from the student.
    def submit_response_of_student(quiz, user, page_parameter, role_of_user, quiz_question_params, commit_message)
      quiz_submission = QuizSubmission.find_by(user_id: user.id, quiz_id: quiz.id)
      unless page_parameter.present?
        # If all the questions are submitted at once.
        if quiz_submission.present?
          # Checking the number of allowed attempts.
          if (quiz.allowed_attempts?) && (quiz_submission.quiz_submission_attempts.count < quiz.allowed_attempts)
            submitted_quiz_by_student = quiz_submission
          else
            return api_error(status: 200, errors: "Maximum attempt reached")
          end
        else
          submitted_quiz_by_student = QuizSubmission.create(user_id: user.id, quiz_id: quiz.id)
        end
        submission_data = []
        # Submitting the new attempt for the student.
        quiz_submission_attempt = submitted_quiz_by_student.quiz_submission_attempts.build( :submission_data => submission_data , :created_at => quiz.created_at, :created_by => user.id, :updated_by => user.id, :started_at => Time.zone.now)
        if quiz_submission_attempt.save
          quiz_submission(quiz, user, role_of_user, submitted_quiz_by_student.id, quiz_submission_attempt.id, quiz_question_params, page_parameter, nil)
        else
          return api_error(status: 400, errors: "Sorry, something went wrong.")
        end
      else
        # If the submission is for one by one question quiz.
        quiz_submission(quiz, user, role_of_user, quiz_submission, quiz_submission_attempt.id, quiz_question_params, page_parameter, commit_message)
      end
    end

    # Quiz submission creation and quiz submission attempt submission.
    def quiz_submission(quiz, user, role_of_user, submission_id, quiz_submission_attempt_id, quiz_question_params, page_parameter, commit_message)
      if role_of_user == "Student"
        if submission_id.present?
          quiz_submission_attempt = QuizSubmissionAttempt.find(quiz_submission_attempt_id)
          # Checking the question params are present or not.
          if quiz_question_params.present?
            submission_data = []
            YAML.load(quiz_question_params.gsub("=>", ":")).each do |d|
              submission_data  << d
            end
            quiz_submission_data = []
            quiz_submission_attempt.submission_data.each do |i|  quiz_submission_data << i if i[0] != submission_data[0][0] end
            quiz_submission_attempt.update_attribute(:submission_data, submission_data + quiz_submission_data)
          end
        end
        quiz_questions = quiz.quiz_questions
        # Setting up the quiz parameters.
        one_question_at_a_time, time_limit_check, time_limit, shuffle_question, lock_question_after_answer = quiz.one_question_at_a_time, quiz.time_limit_check, quiz.time_limit, quiz.shuffle_answers, quiz.lock_question_after_answer
        # Shuffling the question of the quiz.
        if shuffle_question == true
          unless TemporaryData.get_tmp_data(user.id, quiz_submission_attempt.id).present?
            quiz_questions = do_shuffle_question(quiz_questions)
            TemporaryData.set_tmp_data(user.id, quiz_submission_attempt.id, quiz_questions)
          else
            quiz_questions = TemporaryData.get_tmp_data(user.id, quiz_submission_attempt.id)[0]['data']
          end
        end
        # Shuffling the answer options.
        quiz_questions = do_shuffle_answer(quiz_questions)
        # One by one question
        if one_question_at_a_time == true
          page_parameter = page_parameter.present? ? (commit_message == "Previous") ? page_parameter.to_i - 1 : page_parameter.to_i + 1 : 1
          quiz_questions = Kaminari.paginate_array(quiz_questions).page(page_parameter).per(1)
          if commit_message == "Previous" || commit_message == "Next"
            selected_ans = []
            quiz_submission_attempt.submission_data.each do |i|
              if quiz_questions.first.question_id == i[0].to_i
                if quiz_questions.first.question_type == "short_answer_question"
                  selected_ans << i[1]["answers"]["0"]["answer"]
                elsif quiz_questions.first.question_type == "matching_question" || quiz_questions.first.question_type == "multiple_answers_question"
                  selected_ans << i[1]["answers"]
                else
                  selected_ans << i[1]["answer"]
                end
              end
            end
            return {quiz_submission_attempt_id: quiz_submission_attempt.id, quiz_submission_id: quiz_submission_attempt.quiz_submission_id, quiz_id: quiz.id, quiz_question: quiz_questions, page: page_parameter, total_page: quiz.quiz_questions.count, lock_question: lock_question_after_answer, selected_ans: selected_ans }
          else
            return { quiz_submission_attempt_id: quiz_submission_attempt.id, quiz_submission_id: quiz_submission_attempt.quiz_submission_id, quiz_id: quiz.id, quiz_title: quiz.title, quiz_description: quiz.description, total_page: quiz.quiz_questions.count, quiz_question: quiz_questions, page: page_parameter, time_spent: quiz_submission_attempt.time_spent.nil? ? "0".to_i : quiz_submission_attempt.time_spent, time_limit: quiz.time_limit, time_limit_check: quiz.time_limit_check }
          end
        else
          return { quiz_submission_attempt_id: quiz_submission_attempt.id, quiz_submission_id: quiz_submission_attempt.quiz_submission_id, quiz_question: quiz_questions, quiz_id: quiz.id, quiz_title: quiz.title, quiz_description: quiz.description, total_page: quiz.quiz_questions.count, time_spent: quiz_submission_attempt.time_spent, time_limit: quiz.time_limit,time_limit_check: quiz.time_limit_check }
        end
      end
    end

    # Shuffle Question.
    def do_shuffle_question(quiz_questions)
      quiz_questions = quiz_questions.to_a.shuffle
      return quiz_questions
    end

    # Shuffle answer options for particular questions.
    def do_shuffle_answer(quiz_questions)
      quiz_questions.each do |i|
        if i[:question_data][:shuffle_answer] == "on"
          shuffle_ans = Hash[i.question_data[:answers].to_a.shuffle]
        else
          shuffle_ans = i.question_data[:answers]
        end
        i.question_data[:answers] = shuffle_ans
      end
      return quiz_questions
    end

  end
end
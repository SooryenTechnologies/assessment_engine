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

module Api::V1::QuizSubmission::QuizSubmissionAttempt
  class QuizSubmissionAttemptBuilder

    # Method to calculate quiz grading and point calculation
    def calculate_quiz_result(quiz_submission_attempt, quiz_id, user)
      quiz_answers_attempt = quiz_submission_attempt.submission_data
      quiz = Quiz.includes(:quiz_questions).find(quiz_id)
      quiz_questions = quiz.quiz_questions
      # To get answer array for particular question
      answer_array = get_answer_array_for_question(quiz_questions)

      score = 0
      quiz_answers_attempt.each do |attempt|
        count = 0
        attempt = attempt.flatten
        k = []
        question_answer = answer_array.select{|l| l[:id] == attempt[0].to_i}
        # Grading the answer for attempt according to the question type.
        if question_answer.present?
          if question_answer.first[:question_type] == "short_answer_question"
            # Fill in the blanks.
            question_answer.first[:answers].each do |ans|
              if(count == 0)
                if ans.capitalize == (attempt[1]['answers']["0"]["answer"]).capitalize
                  score = score + question_answer.first[:points_possible].to_i
                  count = 1
                end
              end
            end
          elsif question_answer.first[:question_type] == "matching_question"
            # Matching question type.
            user_answer = []
            question_answer.first[:answers].select{|k,v| k.map{|key,val| user_answer << val}}
            actual_answer = attempt[1]["answers"].sort.map{|i| i[1]}
            actual_answer.all? {|e| user_answer.include?(e)}
            score = score + question_answer.first[:points_possible].to_i if actual_answer.all? {|e| user_answer.include?(e)}
          elsif question_answer.first[:question_type] == "multiple_answers_question"
            attempt[1]["answers"].each do |key,v| k << key.to_i if v["answer"].to_i == 1 end
            score = score + question_answer.first[:points_possible].to_i if (question_answer.first[:answers] == k.sort)
          else
            score = score + question_answer.first[:points_possible].to_i if (question_answer.first[:answers] == [attempt[1]['answer'].to_i])
          end
        end
      end

      total_submission = QuizSubmission.where(user_id: user.id, quiz_id: quiz.id)
      quiz_submission_attempt.update_attribute(:score, score)
      quiz_submission_attempt.update_attribute(:end_at ,quiz_submission_attempt["updated_at"])
      quiz_submission_attempt.update_attribute(:finished_at ,quiz_submission_attempt["updated_at"])
      return {success: 200, score: score, message: "Done", attempt_history: total_submission.first.quiz_submission_attempts , quiz_id: quiz.id , quiz: quiz }
    end

    # To get users attempt history.
    def user_attempt_history(quiz_submission_attempt, quiz)
      if quiz.show_correct_answers && (Date.parse(quiz.show_correct_answers_at_date.to_s) == Date.today)  && (Date.parse(quiz.hide_correct_answers_at_date.to_s) != Date.today)
        show_correct_answer = true
      elsif quiz.show_correct_answers && (quiz.show_correct_answers_at_date.present? || quiz.hide_correct_answers_at_date.present?) && quiz.once_after_each_attempt
        show_correct_answer = true
      else
        show_correct_answer = false
      end
      score = quiz_submission_attempt["score"]
      quiz_answers_attempt = quiz_submission_attempt.submission_data
      quiz_questions = quiz.quiz_questions

      # To get answer array for particular question
      answer_array = get_answer_array_for_question(quiz_questions)

      correct = []
      # To collect correct answers in the array.
      quiz_answers_attempt.each do |a1|
        a1 = a1.flatten
        k = []
        question_answer = answer_array.select{|l| l[:id] == a1[0].to_i}
        # Grading the answer options submitted by the student.
        if question_answer.present?
          if question_answer.first[:question_type] == "short_answer_question"
            question_answer.first[:answers].each do |ans|
              count = 0
              if(count == 0)
                if ans.capitalize == (a1[1]['answers']["0"]["answer"]).capitalize
                  correct << a1[0]
                  count = 1
                end
              end
            end
          elsif question_answer.first[:question_type] == "matching_question"
              user_answer = []
              question_answer.first[:answers].select{|k,v| k.map{|key,val| user_answer << val}}
              actual_answer = a1[1]["answers"].sort.map{|i| i[1]}
              actual_answer.all? {|e| user_answer.include?(e)}
            if actual_answer.all? {|e| user_answer.include?(e)}
              correct << a1[0]
            end
          elsif question_answer.first[:question_type] == "multiple_answers_question"
            a1[1]["answers"].each do |key,v| k << key.to_i if v["answer"].to_i == 1 end
            if (question_answer.first[:answers] == k.sort)
              correct << a1[0]
            end
          else
            if (question_answer.first[:answers] == [a1[1]['answer'].to_i])
              correct << a1[0]
            end
          end
        end
      end
      # Auto submission if the time limit is reached for the quiz.
      submitted_at = quiz_submission_attempt.finished_at.strftime("%b %d at %H:%M %p")
      time_spent = quiz_submission_attempt.time_spent
      show_history = []
      quiz_questions.each do |quiz_question|
        quiz_submission_attempt.submission_data.each do |user_answer|
          if quiz_question.question_id == user_answer[0].to_i
            quiz_question.question_data[:user_ans] = user_answer[1]
          end
        end
        show_history << quiz_question
      end
      return {show_history: show_history, quiz: quiz, question_count: quiz.quiz_questions.count, correct: correct, score: score, show_correct_answer: show_correct_answer, submitted_at: submitted_at, time_spent: time_spent}
    end

    # Get answer array for questions.
    def get_answer_array_for_question(quiz_questions)
      answer_array = []
      quiz_questions.each do |q|
        correct_answer = []
        # Collecting correct answer options for questions.
        q.question_data[:answers].each do |a|
          if (a[1]['right_or_wrong'] == 'true')
            correct_answer << a[1]["id"] if q[:question_type] != "short_answer_question"
            correct_answer << a[1]['text'] if q[:question_type] == "short_answer_question"
          else
            correct_answer << {a[1]["id"].to_i => {a[1]['left'] => a[1]['right']}} if q[:question_type] == "matching_question"
          end
        end
        answer_array << {id: q.question_id, quiz_id: q.quiz_id, question_type: q.question_type, points_possible: q.question_data[:points_possible], answers: correct_answer }
      end
      return answer_array
    end

  end
end
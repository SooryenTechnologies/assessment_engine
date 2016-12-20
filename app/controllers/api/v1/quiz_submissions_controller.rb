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

class Api::V1::QuizSubmissionsController < Api::V1::BaseController
  before_filter :authenticate_client!
  before_filter :find_quiz

  # Create the submission of a quiz for the user
  # Mandatory params: context_id, user_id, role, quiz_question
  def create
    set_time_zone(params[:time_zone])
    if params[:context_id].present?
      role_of_user = is_instructor_or_student(params[:user_id], params[:role], params[:context_id])
      context = get_course(params[:context_id])
      if role_of_user.nil?
        new_user = create_student(context)
        role_of_user = is_instructor_or_student(params[:user_id], new_user['role'], params[:context_id])
      end
      # Find role on the basis of params user_id.
      if role_of_user.present? && role_of_user == "Student"
        quiz_submission = Api::V1::QuizSubmission::QuizSubmission::QuizSubmissionBuilder.new().submit_response_of_student(@quiz, @user, params[:page], role_of_user, params[:quiz_question], nil)
        render( json: quiz_submission )
      else
        return api_error(status: 403, errors: 'You are not authorized to perform this action.')
      end
    else
      return api_error(status: 404, errors: 'Context is required.')
    end
  end

  # This method will update the quiz submission when user submits the quiz
  # Mandatory params: context_id, user_id, role, page, commit, submission_id, quiz_question, submission_attempt_id
  def update
    if params[:context_id].present?
      role_of_user = is_instructor_or_student(params[:user_id], params[:role], params[:context_id])
      context = get_course(params[:context_id])
      page_parameter = params[:page].present? ? params[:page] : nil
      if role_of_user.present? && role_of_user == "Student"
        if params[:commit] == "Next" || params[:commit] == "Previous"
          acquired_question = Api::V1::QuizSubmission::QuizSubmission::QuizSubmissionBuilder.new().quiz_submission(@quiz, @user, role_of_user, params[:submission_id], params[:submission_attempt_id], params[:quiz_question], page_parameter, params[:commit])
          render(
            json: acquired_question
          )
        else
          if params[:submission_id].present?
            quiz_submission_attempt = QuizSubmissionAttempt.find(params[:submission_attempt_id])
            if params[:quiz_question].present?
              submission_data = []
              YAML.load(params[:quiz_question].gsub("=>", ":")).each do |d|
                 submission_data  << d
              end
              quiz_submission_data = []
              quiz_submission_attempt.submission_data.each do |i|  quiz_submission_data << i if i[0] != submission_data[0][0] end
              quiz_submission_attempt.update_attribute(:submission_data, submission_data + quiz_submission_data)
            end
            Api::V1::QuizSubmission::QuizSubmission::QuizSubmissionBuilder.new().quiz_submission(@quiz, @user, role_of_user, params[:submission_id], params[:submission_attempt_id], params[:quiz_question], page_parameter, nil)
            quiz_submission_attempt.update_attribute(:time_spent, params["time"].to_i)
            acquired_score = Api::V1::QuizSubmission::QuizSubmissionAttempt::QuizSubmissionAttemptBuilder.new().calculate_quiz_result(quiz_submission_attempt, @quiz.id, @user)

            render(
              json: acquired_score
            )
          else
            return api_error(status: 404, errors: "No submission found.")
          end
        end
      end
    end
  end

  # This method is used for grading purpose, it will be shown only when the quiz is submitted.
  # Mandatory params: context_id, user_id, role, quiz_question, submission_attempt_id
  def grade_quiz
    if params[:quiz_question].present?
      role_of_user = is_instructor_or_student(params[:user_id], params[:role], params[:context_id])
      context = get_course(params[:context_id])
      if role_of_user.present? && role_of_user == "Student"
        quiz_answers_attempt = QuizSubmissionAttempt.find(params[:submission_attempt_id]).submission_data
        quiz_answers_attempt_data = QuizQuestion.where(quiz_id: @quiz.id, question_id: @question.id).first
        quiz_answers_true = []
        quiz_answers_attempt_data["question_data"][:answers].each do |d|
          quiz_answers_true << d[1][:id] if d[1]["right_or_wrong"] == "true"
        end
      end
    end
  end

  # This method tracks time limit of quiz for the user
  # Mandatory params: time_limit, user_id, quiz_id
  def timed_quiz
    if params[:quiz_id].present?
      # Getting quiz submission
      quiz_submission = QuizSubmission.where(user_id: @user.id, quiz_id: @quiz.id)
      # Condition to check if the number of submission attempts is lesser than allowed attempts
      if (@quiz.allowed_attempts.present?) && (quiz_submission.first.quiz_submission_attempts.count < @quiz.allowed_attempts)
        # Condition to see if time limit is present
        if Quiz.find(@quiz.id)["time_limit"].present? == false && @quiz.time_limit_check == true
          # Condition to check if the current time is lesser than lock date and greater than unlock date
          if DateTime.now.strftime < @quiz.lock_at && DateTime.now.strftime > @quiz.unlock_at
            # Calculating time left based on updated attempts timestamp
            if (@quiz.time_left <= @quiz.time_limit)
              return QuizSubmissionAttempt.new
            end
          end
        end
      end
    end
  end

  # Mandatory params: context_id, user_id, role, quiz_submission_id, quiz_id
  def show
    if params[:context_id].present?
      role_of_user = is_instructor_or_student(params[:user_id], params[:role], params[:context_id])
      context = get_course(params[:context_id])
      # Find role on the basis of params user_id.
      if role_of_user.present? && role_of_user == "Student"
        if params[:quiz_submission_id].present?
          quiz_submission_attempt = QuizSubmission.where(params[:quiz_id], params[:user_id]).first.quiz_submission_attempts
        end
      end
    end
  end

  # Method for managing the quiz submission results
  # Mandatory params: context_id, user_id, role, quiz_submission_id, submission_attempt_id
  def quiz_submission_results
    if params[:context_id].present?
      role_of_user = is_instructor_or_student(params[:user_id], params[:role], params[:context_id])
      quiz_submission_attempt = QuizSubmissionAttempt.find(params[:submission_attempt_id])
      if role_of_user.present? && role_of_user == "Student"
        if @quiz.show_quiz_response == true
          quiz_submission_id = quiz_submission_attempt.quiz_submission_id
          quiz_submission = QuizSubmission.includes(:quiz_submission_attempts).find(quiz_submission_id)
          last_attempt_id = quiz_submission.quiz_submission_attempts.last.id
          quiz_submission.quiz_submission_attempts.each do |i|
            i.update_attribute(:was_preview, 1) if i.id != last_attempt_id
          end
          quiz_submission_attempt = QuizSubmissionAttempt.find(params[:submission_attempt_id])
          if @quiz.once_after_each_attempt && quiz_submission_attempt.was_preview.nil?
            attempts = Api::V1::QuizSubmission::QuizSubmissionAttempt::QuizSubmissionAttemptBuilder.new().user_attempt_history(quiz_submission_attempt, @quiz)
            render(
              json: attempts
            )
            quiz_submission_attempt.update_attribute(:was_preview, 1)
          elsif @quiz.once_after_each_attempt && quiz_submission_attempt.was_preview == true
            return api_error(status: 403, errors: "Not allowed to view attempts more than once")
          else
            attempts = Api::V1::QuizSubmission::QuizSubmissionAttempt::QuizSubmissionAttemptBuilder.new().user_attempt_history(quiz_submission_attempt, @quiz)
            render(
              json: attempts
            )
          end
        else
          return api_error(status: 403, errors: "Not allowed to view attempts")
        end
      elsif role_of_user.present? && role_of_user == "Instructor"
        attempts = Api::V1::QuizSubmission::QuizSubmissionAttempt::QuizSubmissionAttemptBuilder.new().user_attempt_history(quiz_submission_attempt, @quiz)
        render(
          json: attempts
        )
      end
    end
  end

  # Get number of user attempts for particular quiz.
  # Mandatory params: quiz_id, user_id
  def get_user_attempts
    if params[:quiz_id].present? && params[:user_id].present?
      quiz_submission_attempt = QuizSubmission.where(quiz_id: @quiz.id, user_id: find_user(params[:user_id]))
      if quiz_submission_attempt.present?
        quiz_submission_attempt = quiz_submission_attempt.first.quiz_submission_attempts
        render(
          json: { attempt_history: quiz_submission_attempt }
        )
      else
        return api_error(status: 403, errors: "No attempts found")
      end
    end
  end

  # Method for managing the quiz submission attempts for all or for one by one question.
  # Mandatory params: context_id, user_id, role, submission_id submission_attempt_id, quiz_question, commit
  # def whole_next_previous
  #   if params[:context_id].present?
  #     role_of_user = is_instructor_or_student(params[:user_id], params[:role], params[:context_id])
  #     context = get_course(params[:context_id])
  #     acquired_question = Api::V1::QuizSubmission::QuizSubmission::QuizSubmissionBuilder.new().quiz_submission(@quiz, @user, role_of_user, params[:submission_id], params[:submission_attempt_id], params[:quiz_question], page_parameter, params[:commit])
  #     render(
  #       json: acquired_question
  #     )
  #   end
  # end

  # Swagger Documents.
  swagger_controller :QuizSubmissions, 'QuizSubmissions'

  swagger_api :create do
    summary "Submit the response for quiz."
    notes "Submit the response/attempt of the student for the quiz."
    param :query, :context_id, :string, :required, "Context Id"
    param :query, :user_id, :string, :required, "User Id"
    param :query, :role, :string, :required, "Role (For Student only.)"
    param :query, :first_name, :string, :required, "First name of the student."
    param :query, :last_name, :string, :required, "Last name of the student."
    param :query, :email, :string, :required, "Email of the student."
    param :path, :quiz_id, :string, :required, "Resource link id"
    param :header, 'X-API-KEY', :string, :required, 'Authentication token'

    response :unauthorized
  end

  private

  def quiz_submission_params
    params.require(:quiz_submission).permit(:quiz_id, :user_id)
  end

  # To find/create student and his permission for particular context.
  def create_student(context)
    user_present = User.where(first_name: params[:first_name], last_name: params[:last_name], email: params[:email], recieved_user_id: params[:user_id])
    if user_present.present?
      # if user is present.
      @user = user_present.first
      user_permission = UsersPermission.where(client_id: @current_client.id, user_id: @user.id, context_id: context.id)
      unless user_permission.present?
        return user_permission = UsersPermission.create(client_id: @current_client.id, user_id: @user.id, role: "Student", context_id: context.id)
      end
    else
      # if not create student and permission.
      @user = User.new(first_name: params[:first_name], last_name: params[:last_name], email: params[:email], recieved_user_id: params[:user_id])
      if @user.save
        user_permission = UsersPermission.create(client_id: @current_client.id, user_id: @user.id, role: "Student", context_id: context.id)
      else
        @errors = user.errors.full_messages
      end
    end
  end

end
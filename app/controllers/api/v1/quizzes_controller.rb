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

class Api::V1::QuizzesController < Api::V1::BaseController
  before_filter :authenticate_client!

  # To create the quiz and also to check that the context is created or not.
  # Checks the role for quiz and it should be created by the instructor only.
  # Mandatory params: context_id, user_id, role, user_id, first_name, last_name, email, resource_link_id
  def create
    quiz_parameters = Quiz.set_quiz_parameters(params[:quiz].to_s)
    if quiz_parameters[:context_id].present?
      role_of_user = is_instructor_or_student(params[:user_id], params[:role], quiz_parameters[:context_id])
      context = get_course(quiz_parameters[:context_id])
      # Find role on the basis of params user_id.
      if role_of_user.present? && role_of_user == "Instructor"
        quiz = Quiz.find_by(context_id: context.id, created_by: @user.id, updated_by: @user.id, resource_link_id: quiz_parameters[:resource_link_id])
        # If user is present and role is instructor then create quiz.
        if quiz.present?
          render(
            json: {quiz: quiz, total_questions_count: quiz.quiz_questions.count}
          )
        else
          quiz_creation = Quiz.quiz_create(quiz_parameters, context.id, @user.id)
          if quiz_creation[:status] == 200
            render(
              json: quiz_creation
            )
          else
            return api_error(status: 422, errors: quiz_creation[:errors])
          end
        end
      else
        # If the user is present then check the role of user has been sent.
        if params[:role] == "Instructor"
          # If context is created or not.
          unless context.present?
            # Create context.
            context = Context.create(context: quiz_parameters[:context_id])
          end
          # Create instructor and add role.
          user_created_or_not = User.create_instructor_or_student(context, params[:first_name], params[:last_name], params[:email], params[:user_id], @current_client, "Instructor")
          # create_instructor(context)
          if user_created_or_not[:status] == "User Created"
            # Create quiz.
            user = user_created_or_not[:user]
            quiz_creation = Quiz.quiz_create(quiz_parameters, context.id, user.id )
            if quiz_creation[:status] == 200
              render(
                json: quiz_creation
              )
            else
              return api_error(status: 422, errors: quiz.errors.full_messages)
            end
          else
            # Errors
            return api_error(status: 422, errors: user_created_or_not[:errors])
          end
        else
          # For student role.
          return api_error(status: 403, errors: "You are not authorized to perform this action")
        end
      end
    else
      return api_error(status: 401, errors: "Context is required.")
    end
  end

  # To get the list of the quizzes for context.
  # Mandatory parameters: user_id, context_id, role and client id
  def index
    begin
      context = get_course(params[:context_id])
      user_role = is_instructor_or_student(params[:user_id], params[:role], params[:context_id])
      if (Quiz::ALLOWED_ROLES.include? user_role) && context.present?
        quizzes = Quiz.where(context_id: context.id, created_by: @user.id, updated_by: @user.id)
        response = quizzes
      else
        response = {error: "Not authorized to get list."}
      end
    rescue => exception
      response = exception
      Rails.logger.fatal "({Controller: Quiz, action: index}) ==> Error :====> exception: #{response}"
    end
    render(
      json: response
    )
  end

  # To show the specific quiz.
  # Mandatory parameters: resource_link_id as an id
  def show
    begin
      quiz = Quiz.includes(:quiz_questions).find_by(resource_link_id: params[:id])
      if quiz.present?
        render(
          json: {quiz: quiz, total_questions_count: quiz.quiz_questions.count, quiz_editable: check_quiz_editable_or_not(quiz.id)}
        )
      else
        return api_error(status: 404, errors: "Quiz not found.")
      end
    rescue => exception
      response = exception
      Rails.logger.fatal "({Controller: Quiz, action: show}) ==> Error :====> #{exception}: #{response}"
      return api_error(status: 404, errors: response)
    end
  end

  # To delete/destroy the specific quiz.
  # Mandatory parameters: resource_link_id as an id
  def destroy
    begin
      # Find quiz with particular resource link id.
      quiz = Quiz.find_by(resource_link_id: params[:id])
      if quiz.present? && quiz.destroy
        response = "The quiz is deleted successfully."
      else
        response = "The quiz can not be deleted."
      end
    rescue => exception
      response = exception
      Rails.logger.fatal "({Controller: Quiz, action: destroy}) ==> Error :====> #{exception}: #{response}"
    end
    render(
      json: {quiz: response}
    )
  end

  # To show the specific quiz.
  # Mandatory params: context_id, resource_link_id.
  def update
    # Set acquired quiz parameters.
    quiz_parameters = Quiz.set_quiz_parameters(params[:quiz].to_s)
    # Find Quiz with respect to resource_link_id.
    quiz = Quiz.find_by(resource_link_id: quiz_parameters[:resource_link_id], context_id: get_course(quiz_parameters[:context_id]))
    if quiz.present?
      quiz_parameters[:context_id] = Context.find_by_context(quiz_parameters[:context_id].to_i).id.to_s
      if quiz.update_attributes(quiz_parameters)
        render(
          json: {quiz: quiz, total_questions_count: quiz.quiz_questions.count, quiz_editable: check_quiz_editable_or_not(quiz.id)}
        )
      else
        return api_error(status: 422, errors: quiz.errors)
      end
    else
      return api_error(status: 404, errors: "Quiz not found.")
    end
  end

  # Duplicate already created quiz with all its questions.
  # Mandatory params: context_id, user_id, role, source_resource_link_id, destination_resource_link_id.
  def duplicate_quiz
    role_of_user = is_instructor_or_student(params[:user_id], params[:role], params[:context_id])
    context = get_course(params[:context_id])
    # If allowed duplicate the quiz.
    if Quiz::ALLOWED_ROLES.include? role_of_user
      source_resource_link_id = params[:source_resource_link_id]
      destination_resource_link_id = params[:destination_resource_link_id]
      if source_resource_link_id.present? && destination_resource_link_id.present?
        source_quiz = Quiz.find_by(resource_link_id: source_resource_link_id)
        if source_quiz.present?
          # Create new quiz for source quiz.
          destination_quiz = Quiz.new(source_quiz.attributes.merge(id: nil))
          destination_quiz.resource_link_id = destination_resource_link_id
          if destination_quiz.save
            # Find quiz questions and duplicate new questions for newly created quiz.
            questions = source_quiz.quiz_questions
            if questions.present?
              questions.each do |q|
                new_question = q.dup
                new_question.update_attribute(:quiz_id, destination_quiz.id)
              end
            end
            render(
              json: destination_quiz
            )
          else
            return api_error(status: 400, errors: destination_quiz.errors)
          end
        else
          return api_error(status: 404, errors: "Quiz not found.")
        end
      else
        return api_error(status: 403, errors: "Please send Source and Destination resource link id.")
      end
    else
      return api_error(status: 403, errors: "You are not authenticated to perform this action")
    end
  end

  # To get the scores for students/student according to the parameters passed.
  # Mandatory params: context_id, user_id, role, resource_link_ids (in array), destination_resource_link_id.
  def get_the_scores_information
    if params[:context_id].present?
      role_of_user = is_instructor_or_student(params[:user_id], params[:role], params[:context_id])
      context = get_course(params[:context_id])
      # Find role on the basis of params user_id.
      if role_of_user.present?
        if params[:resource_link_ids] == "All" || !params[:resource_link_ids].present?
          quizzes = Quiz.where(context_id: context.id)
        else
          quizzes = Quiz.where(context_id: context.id, resource_link_id: params[:resource_link_ids])
        end
        if quizzes.present?
          # Get result for all quizzes.
          result = Quiz.get_result_of_all_quizzes(quizzes)
          render(
            json: result
          )
        else
          return api_error(status: 404, errors: "Quizzes not found.")
        end
      else
        return api_error(status: 404, errors: "Scores for these quizzes not found.")
      end
    else
      return api_error(status: 403, errors: "Context id is required.")
    end
  end

  # Searching question from question banks for adding/attaching to the quiz.
  # Mandatory params: questions_id, sort_by_questions(type(question_type: short_answer_question, fill_in_the_blanks)), question_order.
  def question_bank
    if params["search"].present? || params[:questions_id].present?
      if params["search"].present?
        # Search by text.
        questions = Question.where("question_data LIKE ?", "%#{params["search"]}%")
      else
        if params[:questions_id].is_a?(Array)
          # Search by the question ids
          question_ids = params[:questions_id]
        else
          question_ids = YAML.load(params[:questions_id])
        end
        questions = Question.where(:id => question_ids)
      end
      # Sort according to the parameters passed by the user.
      questions = questions.sort_by{|k| (params["sort_by_questions"] == "type") ? (k[:question_data][:question_type] == "short_answer_question" ? "fill_in_the_blanks".titleize : k[:question_data][:question_type].titleize) : k[:question_data][:question_text].titleize}
      if params["questions_order"].present? && params["questions_order"] == "DESC"
        questions = questions.reverse
      else
        questions = questions
      end
      if questions.present?
        render(
          json: questions
        )
      else
        return api_error(status: 404, errors: "No question found.")
      end
    else
      return api_error(status: 404, errors: "No question found.")
    end
  end

  # To get assessments according to the resource link ids that are passed.
  # Mandatory parameters: context_id, role, user_id,
  # sort_parameter (assessment-title/due-date/total-points/question-count)
  def get_assessments_by_resource_link_ids
    begin
      context = get_course(params[:context_id])
      user_role = is_instructor_or_student(params[:user_id], params[:role], params[:context_id])
      if user_role.present? && context.present?
        # Find quiz according to the resource link ids with the sort parameter.
        quiz_list = Quiz.where(resource_link_id: params[:resource_link_ids])
        if params['sort_parameter'] == "assessment-title"
          quizzes = quiz_list.order('title ' + params[:order])
        elsif params['sort_parameter'] == "due-date"
          quizzes = quiz_list
        elsif params['sort_parameter'] == "total-points"
          quizzes = quiz_list.order('points_possible ' + params[:order])
        elsif params['sort_parameter'] == "question-count"
          quizzes = quiz_list.order('question_count ' + params[:order])
        else
          quizzes = quiz_list.order('title ASC')
        end
        response = quizzes
      else
        # Not authorized to get list.
        response = {error: "Not authorized to get list."}
      end
    rescue => exception
      response = exception
      Rails.logger.fatal "({Controller: Quiz, action: index}) ==> Error :====> exception: #{response}"
    end
    render(
      json: response
    )
  end

  # Add question from question bank(questions table) to quiz.
  # Mandatory parameters: context_id, role, user_id,
  # resource_link_id, questions_id[]
  def add_question_to_quiz
    role_of_user = is_instructor_or_student(params[:user_id], params[:role], params[:context_id])
    if role_of_user == "Instructor"
      quiz = Quiz.find_by(resource_link_id: params[:resource_link_id], context_id: get_course(params[:context_id]))
      if quiz.present?
        if params["questions_id"].present?
          question_ids = params["questions_id"]
          # Duplicate the quiz question from the bank and add to the mentioned quiz.
          questions_list = QuizQuestion.duplicate_quiz_question(quiz, question_ids, @user.id)
          # update the score(point_possible) and question_count of the quiz.
          updated_score = quiz.quiz_questions.map{|l| l[:question_data][:points_possible].to_f}.flatten.sum
          quiz.update_attributes(points_possible: updated_score, question_count: quiz.quiz_questions.count)
          render(
            json: {quiz_questions: questions_list, quiz_total_score: updated_score, total_questions_count: quiz.quiz_questions.count, quiz_editable: check_quiz_editable_or_not(quiz.id)}
          )
        else
          return api_error(status: 400, errors: questions.errors)
        end
      else
        return api_error(status: 404, errors: "Quiz not found.")
      end
    else
      return api_error(status: 403, errors: "You are not authenticated to perform this action.")
    end
  end

  # Swagger Documents.
  swagger_controller :Quizzes, 'Quizzes'

  swagger_api :index do
    summary "Fetches all Quizzes."
    notes "List of all quizzes for context(Course/Section) passed by the user."
    param :query, :context_id, :string, "Context Id", "Course or section id"
    param :query, :user_id, :string, "User Id", "User Id"
    param :query, :role, :string, "Role", "Role of User"
    param :header, 'X-API-KEY', :string, :required, 'Authentication token'
    response :unauthorized
  end

  swagger_api :create do
    summary "Create Quiz."
    notes "Quiz Creation for particular context "
    param :query, :first_name, :string, :required, "First Name"
    param :query, :last_name, :string, :required, "Last Name"
    param :query, :email, :string, :required, "Email"
    param :query, :user_id, :string, :required, "User Id"
    param :query, :role, :string, :required, "Role [ 'Instructor', 'Student' ]"
    param :header, 'X-API-KEY', :string, :required, 'Authentication token'
    param :form, "quiz[title]", :string, :required, "Quiz Title"
    param :form, "quiz[description]", :string, :required, "Quiz Description"
    param :form, "quiz[context_id]", :string, :required, "Context Id"
    param :form, "quiz[quiz_type]", :string, :required, "Quiz type. [graded_assessment]"
    param :form, "quiz[resource_link_id]", :string, :required, "Resource Link Id. It should be unique key to recognize the quiz."
    param :form, "quiz[time_limit_check]", :boolean, :optional, "Quiz Time limit Check. If user checked this then quiz will be timed."
    param :form, "quiz[time_limit]", :integer, :optional, "Quiz Time limit. If time_limit_check then only it will work. Value should be in minutes"
    param :form, "quiz[allow_multiple_attempt_check]", :boolean, :optional, "Quiz Allow multiple attempts"
    param :form, "quiz[allowed_attempts]", :integer, :optional, "Allowed attempts allow_multiple_attempt_check is checked then only it will work.(1-10)"
    param :form, "quiz[one_question_at_a_time]", :boolean, :optional, "Single question at a time will be shown to students during quiz submission."
    param :form, "quiz[lock_question_after_answer]", :boolean, :optional, "The question will be locked after student will submit the reponse."
    param :form, "quiz[show_quiz_response]", :boolean, :optional, "Whether to show the quiz response submitted by the student."
    param :form, "quiz[show_correct_answers]", :boolean, :optional, "Whether to show the correct answers to students in quiz response."
    param :form, "quiz[once_after_each_attempt]", :boolean, :optional, "Whether to show response after each attempt."
    param :form, "quiz[show_correct_answers_at_date]", :date, :optional, "Showing the quiz response between these time period. Response start date."
    param :form, "quiz[show_correct_answers_at_time]", :time, :optional, "Response show start time"
    param :form, "quiz[hide_correct_answers_at_date]", :date, :optional, "Response hide end date."
    param :form, "quiz[hide_correct_answers_at_time]", :time, :optional, "Response hide end time."
    param :form, "quiz[lock_at]", :date, :optional, "Lock quiz submission at this date"
    param :form, "quiz[unlock_at]", :date, :optional, "Unlock quiz submission at this date"
    param :form, "quiz[due_at]", :datetime, :optional, "Quiz due at"
    param :form, "quiz[published_at]", :datetime, :optional, "Quiz published at this date."
  end

  swagger_api :update do
    summary "Update Quiz."
    notes "Quiz updation with different attributes "
    param :query, :first_name, :string, :required, "First Name"
    param :query, :last_name, :string, :required, "Last Name"
    param :query, :email, :string, :required, "Email"
    param :query, :user_id, :string, :required, "User Id"
    param :query, :role, :string, :required, "Role [ 'Instructor', 'Student' ]"
    param :header, 'X-API-KEY', :string, :required, 'Authentication token'
    param :form, "quiz[title]", :string, :required, "Quiz Title"
    param :form, "quiz[description]", :string, :required, "Quiz Description"
    param :form, "quiz[context_id]", :string, :required, "Context Id"
    param :form, "quiz[quiz_type]", :string, :required, "Quiz type. [graded_assessment]"
    param :form, "quiz[resource_link_id]", :string, :required, "Resource Link Id. It should be unique key to recognize the quiz."
    param :form, "quiz[time_limit_check]", :boolean, :optional, "Quiz Time limit Check. If user checked this then quiz will be timed."
    param :form, "quiz[time_limit]", :integer, :optional, "Quiz Time limit. If time_limit_check then only it will work. Value should be in minutes"
    param :form, "quiz[allow_multiple_attempt_check]", :boolean, :optional, "Quiz Allow multiple attempts"
    param :form, "quiz[allowed_attempts]", :integer, :optional, "Allowed attempts allow_multiple_attempt_check is checked then only it will work.(1-10)"
    param :form, "quiz[one_question_at_a_time]", :boolean, :optional, "Single question at a time will be shown to students during quiz submission."
    param :form, "quiz[lock_question_after_answer]", :boolean, :optional, "The question will be locked after student will submit the reponse."
    param :form, "quiz[show_quiz_response]", :boolean, :optional, "Whether to show the quiz response submitted by the student."
    param :form, "quiz[show_correct_answers]", :boolean, :optional, "Whether to show the correct answers to students in quiz response."
    param :form, "quiz[once_after_each_attempt]", :boolean, :optional, "Whether to show response after each attempt."
    param :form, "quiz[show_correct_answers_at_date]", :date, :optional, "Showing the quiz response between these time period. Response start date."
    param :form, "quiz[show_correct_answers_at_time]", :time, :optional, "Response show start time"
    param :form, "quiz[hide_correct_answers_at_date]", :date, :optional, "Response hide end date."
    param :form, "quiz[hide_correct_answers_at_time]", :time, :optional, "Response hide end time."
    param :form, "quiz[lock_at]", :date, :optional, "Lock quiz submission at this date"
    param :form, "quiz[unlock_at]", :date, :optional, "Unlock quiz submission at this date"
    param :form, "quiz[due_at]", :datetime, :optional, "Quiz due at"
    param :form, "quiz[published_at]", :datetime, :optional, "Quiz published at this date."
  end

  swagger_api :show do
    summary "Showing the quiz information."
    notes "List of all attributes for the quiz."
    param :path, :id, :string, :required, "Resource Link Id"
    param :header, 'X-API-KEY', :string, :required, 'Authentication token'
    response :unauthorized
  end

  swagger_api :destroy do
    summary "Destroying the quiz."
    notes "Destroying the quiz and all information related to it."
    param :path, :id, :string, :required, "Resource Link Id"
    param :header, 'X-API-KEY', :string, :required, 'Authentication token'
    response :unauthorized
  end

  swagger_api :duplicate_quiz do
    summary "Duplicate Quiz."
    notes "Pass source resource_link_id and destination resource_link_id to duplicate the quiz."
    param :query, :context_id, :string, :required, "Course or section id"
    param :query, :user_id, :string, :required, "User Id"
    param :query, :role, :string, :required, "Role of User"
    param :query, :source_resource_link_id, :string, :required, "Source resource_link_id (Which quiz is to be copied)"
    param :query, :destination_resource_link_id, :string, :required, "Destination resource_link_id (At which quiz the source quiz should be duplicate.)"
    param :header, 'X-API-KEY', :string, :required, 'Authentication token'
    response :unauthorized
  end

  swagger_api :get_the_scores_information do
    summary "Get the score information for all students."
    notes "Pass resource_link_ids to get the information for all scores."
    param :query, :context_id, :string, :required, "Course or section id"
    param :query, :user_id, :string, :required, "User Id"
    param :query, :role, :string, :required, "Role of User"
    param :query, "resource_link_ids[]", :string, "resource_link_id (Which quiz result to be shown). For all keep resource link id nil"
    param :header, 'X-API-KEY', :string, :required, 'Authentication token'
    response :unauthorized
  end

  swagger_api :question_bank do
    summary "Get the questions with the string search or with the ids."
    notes "Pass question ids or string to get the question from question from question bank."
    param :query, :search, :string, :optional, "Search parameter"
    param :query, "questions_id[]", :string, "question id (Which question to be shown)."
    param :header, 'X-API-KEY', :string, :required, 'Authentication token'
    response :unauthorized
  end

  swagger_api :get_assessments_by_resource_link_ids do
    summary "Get the quizzes with the resource_link_ids."
    notes "Pass resource_link_ids to get the quizzes."
    param :query, :context_id, :string, :required, "Course or section id"
    param :query, :user_id, :string, :required, "User Id"
    param :query, :role, :string, :required, "Role of User"
    param :query, "resource_link_ids[]", :string, "resource_link_ids (Which quizzes to be shown)."
    param :header, 'X-API-KEY', :string, :required, 'Authentication token'
    response :unauthorized
  end

  swagger_api :add_question_to_quiz do
    summary "Add questions to the quiz from question bank."
    notes "Pass question_ids to add in the quizzes."
    param :query, :context_id, :string, :required, "Course or section id"
    param :query, :user_id, :string, :required, "User Id"
    param :query, :role, :string, :required, "Role of User"
    param :query, "resource_link_id", :string, "resource_link_id (Which quizzes to be selected to add question)."
    param :query, "questions_id[]", :string, "questions_id (pass questions id which should be added to quiz)."

    param :header, 'X-API-KEY', :string, :required, 'Authentication token'
    response :unauthorized
  end
end
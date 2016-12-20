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

class Api::V1::QuizQuestionsController < Api::V1::BaseController
  before_filter :authenticate_client!
  before_filter :find_quiz, except: [:destroy, :question_bank]

  # To create new question for the quiz.
  # Mandatory parameters: context_id, user_id, role, resource_link_id
  # and question parameters.
  def create
    if params[:context_id].present?
      role_of_user = is_instructor_or_student(params[:user_id], params[:role], params[:context_id])
      context = get_course(params[:context_id])
      # Find role on the basis of params user_id.
      if role_of_user.present? && role_of_user == "Instructor"
        # If the user is present and role is instructor then create quiz_question.
        @question_bank = QuestionBank.where(context_id: context.id)
        if !@question_bank.present?
          @question_bank = QuestionBank.create(title: context.context.to_s + "- Question Bank", context_id: context.id, user_id: @user.id, created_by: @user.id, updated_by: @user.id)
        end
        if @quiz.present?
          # Check if question is added from question bank to quiz.
          if params["question_from_question_bank"].present?
            if params["question"].present?
              question = Question.find(params["question"])
              # Create a new question and update the question data to the question bank.
              quiz_question = @quiz.quiz_questions.build(question_id: question.id, :question_data => question.question_data, created_by: @user.id, updated_by: @user.id, question_type: question.question_data[:question_type])
              if quiz_question.save
                # Update the score of the quiz.
                updated_score = @quiz.quiz_questions.map{|l| l[:question_data][:points_possible].to_f}.flatten.sum
                @quiz.update_attributes(points_possible: updated_score, question_count: @quiz.quiz_questions.count)
                render(
                  json: {quiz_question: quiz_question, quiz_total_score: updated_score, total_questions_count: @quiz.quiz_questions.count, quiz_editable: check_quiz_editable_or_not(@quiz.id)}
                )
              else
                return api_error(status: 422, errors: quiz_question.errors.full_messages)
              end
            else
              return api_error(status: 404, errors: 'Quiz question not found.')
            end
          else
            # Create the new question, add it to the quiz and question bank.
            question_data = YAML::load(params[:question].gsub("=>", ":")).symbolize_keys

            if (question_data[:question_type] == "matching_question")
              question_data[:answers] = question_data[:answers].reject{|l,v| v["left"].blank? && v["right"].blank?}
            else
              question_data[:answers] = question_data[:answers].reject{|l,v| v["text"].blank?}
            end
            count = 1
            # Collect answer options and store them in db
            answers = question_data[:answers].each do |l|
              l[1]['id'] = count
              count = count + 1
            end
            question_data[:answers] = answers
            # build the new quiz question with parameters.
            quiz_question = @quiz.quiz_questions.build(:question_data => question_data, created_by: @user.id, updated_by: @user.id, question_type: question_data[:question_type])
            if quiz_question.save
              updated_score = @quiz.quiz_questions.map{|l| l[:question_data][:points_possible].to_f}.flatten.sum
              @quiz.update_attributes(points_possible: updated_score, question_count: @quiz.quiz_questions.count)
              render(
                json: {quiz_question: quiz_question, quiz_total_score: updated_score, total_questions_count: @quiz.quiz_questions.count, quiz_editable: check_quiz_editable_or_not(@quiz.id)}
              )
            else
              return api_error(status: 422, errors: quiz_question.errors.full_messages)
            end
          end
        else
          return api_error(status: 404, errors: 'Quiz not found.')
        end
      else
      # For student role.
        return api_error(status: 403, errors: 'You are not authenticated to perform this action.')
      end
    else
      return api_error(status: 400, errors: "Context is required.")
    end
  end

  # To get the list of questions.
  def index
    # If the user is instructor then find questions for that quiz.
    if @quiz.quiz_questions.present?
      render(
        json: @quiz.quiz_questions
      )
    else
      return api_error(status: 404, errors: "There are no questions for this quiz.")
    end
  end

  # To create a new quiz question.
  # Mandatory parameters: context_id, user_id, role, resource_link_id
  # and question parameters.
  def update
    role_of_user = is_instructor_or_student(params[:user_id], params[:role], params[:context_id])
    context = get_course(params[:context_id])
    if role_of_user == "Instructor"
      if @quiz.present?
        quiz_question = QuizQuestion.find(params[:id])
        quiz_editable = check_quiz_editable_or_not(@quiz.id)
        if params["status"] == "cancel_question_update"
          updated_score = @quiz.quiz_questions.map{|l| l[:question_data][:points_possible].to_f}.flatten.sum
          @quiz.update_attribute(:points_possible, updated_score)
          render(
            json: {quiz_question: quiz_question, quiz_total_score: updated_score, total_questions_count: @quiz.quiz_questions.count, quiz_editable: quiz_editable}
          )
        else
          # Serialize the data for storing it in the db.
          question_data = YAML::load(params[:question].gsub("=>", ":")).symbolize_keys
          if (question_data[:question_type] == "matching_question")
            question_data[:answers] = question_data[:answers].reject{|l,v| v["left"].blank? && v["right"].blank?}
          else
            question_data[:answers] = question_data[:answers].reject{|l,v| v["text"].blank?}
          end
          count = 1
          answers = question_data[:answers].each do |l|
            l[1]['id'] = count
            count = count + 1
          end
          # Setting the data answers
          question_data[:answers] = answers
          if quiz_question.update_attributes(question_data: question_data)
            # update score of the quiz.
            updated_score = @quiz.quiz_questions.map{|l| l[:question_data][:points_possible].to_f}.flatten.sum
            @quiz.update_attribute(:points_possible, updated_score)
            render(
              json: {quiz_question: quiz_question, quiz_total_score: updated_score, total_questions_count: @quiz.quiz_questions.count, quiz_editable: quiz_editable}
            )
          else
            return api_error(status: 422, errors: quiz_question.errors.full_messages)
          end
        end
      else
        return api_error(status: 404, errors: "Quiz not found.")
      end
    else
      return api_error(status: 403, errors: "You are not authenticated to perform this action.")
    end
  end

  # To display/show new quiz question.
  # Mandatory parameters: context_id, id(question id)
  def show
    begin
      if params[:context_id].present?
        if @quiz.present?
          quiz_question = QuizQuestion.find(params[:id])
          if quiz_question.present?
          render(
            json: {quiz_question: quiz_question, resource_link_id: @quiz.resource_link_id, question_id: quiz_question.question_id}
          )
          else
            return api_error(status: 404, errors: "Question not found.")
          end
        else
          return api_error(status: 404, errors: "Quiz not found.")
        end
      else
        return api_error(status: 404, errors: "Context id is not present")
      end
    rescue => exception
      response = exception
      Rails.logger.fatal "({Controller: Quiz, action: show}) ==> Error :====> #{exception}: #{response}"
      return api_error(status: 404, errors: response)
    end
  end

  # To delete/destroy new quiz question.
  # Mandatory parameters: id(question id)
  def destroy
    begin
      quiz_question = QuizQuestion.find(params[:id])
      question_id = quiz_question.question_id
      if quiz_question.present? && quiz_question.destroy
        quiz = Quiz.includes(:quiz_questions).find(quiz_question.quiz_id)
        updated_score = quiz.quiz_questions.map{|l| l[:question_data][:points_possible].to_f}.flatten.sum
        quiz.update_attributes(points_possible: updated_score, question_count: quiz.quiz_questions.count)
        render(
          json: {quiz_question: "The Question is deleted successfully.", quiz_question_id: question_id, total_questions_count: quiz.quiz_questions.count }
        )
      else
        return api_error(status: 403, errors: "The Question can not be deleted.")
      end
    rescue => exception
      response = exception
      Rails.logger.fatal "({Controller: QuizQuestion, action: destroy}) ==> Error :====> #{exception}: #{response}"
      return api_error(status: 403, errors: response)
    end
  end

  # Swagger Documents.
  swagger_controller :QuizQuestions, 'QuizQuestions'

  swagger_api :index do
    summary "Fetches all questions attached to Quiz."
    notes "List of all questions attached to quiz."
    param :path, :quiz_id, :string, :required, "Resource link id"
    param :query, :context_id, :string, :required, "Context id"
    param :header, 'X-API-KEY', :string, :required, 'Authentication token'
    response :unauthorized
  end

  swagger_api :create do
    summary "Create Question for quiz."
    notes "Creating the question and attaching it to the quiz."
    param :query, :context_id, :string, :required, "Context Id"
    param :query, :user_id, :string, :required, "User Id"
    param :query, :role, :string, :required, "Role [ 'Instructor', 'Student' ]"
    param :path, :quiz_id, :string, :required, "Resource link id"
    param :header, 'X-API-KEY', :string, :required, 'Authentication token'
    param :form, "question[question_text]", :string, :required, "Question text"
    param :form, "question[question_type]", :string, :required, "Question type [multiple_choice_question true_false_question short_answer_question multiple_answers_question multiple_dropdowns_question matching_question]."
    param :form, "question[points_possible]", :integer, :required, "Point assigned to question."
    param :form, "question[answers]", :enum, :required, "Answer option body."
  end

  # swagger_api :update do
  # end

  swagger_api :show do
    summary "Showing the question information."
    notes "Showing the question information and its attributes."
    param :query, :context_id, :string, :required, "Context Id"
    param :path, :quiz_id, :string, :required, "Resource Link Id"
    param :path, :id, :string, :required, "Question Id"
    param :header, 'X-API-KEY', :string, :required, 'Authentication token'
    response :unauthorized
  end

  swagger_api :destroy do
    summary "Destroying the quiz question."
    notes "Destroying the question and all information related attached to the question."
    param :query, :context_id, :string, :required, "Context Id"
    param :path, :quiz_id, :string, :required, "Resource Link Id"
    param :path, :id, :string, :required, "Question Id"
    param :header, 'X-API-KEY', :string, :required, 'Authentication token'
    response :unauthorized
  end

  private
  def question_params
    params.require(:question).permit(:question_type, :points_possible, :question_text, :answers)
  end
end
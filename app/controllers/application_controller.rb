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

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  # To get the course according to the context.
  def get_course(context_id)
    @context = Context.find_by_context(context_id)
  end

  # Find the role of user.
  def is_instructor_or_student(recieved_user_id, role, context_id)
    @user = find_user(recieved_user_id)
    if @user.present?
      context = get_course(context_id)
      if context.present?
        user_permission = @user.users_permissions.where(client_id: @current_client.id, context_id: context.id)
        if context.present? && user_permission.present?
          role = user_permission.first.role
        else
          role = nil
        end
      else
        role = nil
      end
    else
      role = nil
    end
  end

  # Find user by recieved_user_id.
  def find_user(recieved_user_id)
    @user = User.find_by_recieved_user_id(recieved_user_id)
  end

  # Finding quiz id.
  def find_quiz
    if (params.has_key?(:context_id) && (params.has_key?(:resource_link_id) || params.has_key?(:quiz_id)))
      @quiz = Quiz.where(resource_link_id: (params[:resource_link_id].present? ? params[:resource_link_id] : params[:quiz_id])).first
      if @quiz.present?
        return @quiz
      else
        return api_error(status: 404, errors: "Quiz not found.")
      end
    end
  end

  # Set date format
  def change_date_format(date)
    DateTime.strptime(date,"%m/%d/%Y").to_date
  end

  # Method to check quiz is editable or not
  def check_quiz_editable_or_not(quiz_id)
    quiz_submission = QuizSubmission.includes(:quiz_submission_attempts).find_by(quiz_id: quiz_id)
    if quiz_submission.present? && quiz_submission.quiz_submission_attempts.present?
      return false
    else
      return true
    end
  end

  # Set time-zone in application as per user's time-zone
  def set_time_zone(user_time_zone)
    Time.zone = user_time_zone.to_s
  end

end
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

class Api::V1::QuizSubmissionAttemptsController < Api::V1::BaseController
  before_filter :authenticate_client!
  before_filter :find_quiz

  # This method creates the quiz sumbission attempt of the user for the quiz
  # Mandatory params: context_id, user_id, role, quiz_submission_attempt, quiz
  def create
    if params[:quiz_submission_attempt][:context_id].present?
      role_of_user = is_instructor_or_student(params[:user_id], params[:role], params[:quiz_submission_attempt][:context_id])
      context = get_course(params[:quiz][:context_id])
      # Find role on the basis of params user_id.
      if role_of_user.present? && role_of_user == "Student"
        # If user is present and role is instructor then create quiz.
        quiz_submission = QuizSubmissionAttempt.where(user_id: @user.id, quiz_id: @quiz.id)
        if quiz_submission.present?
          submitted_quiz_by_student = quiz_submission.first
        else
          quiz_submission = QuizSubmissionAttempt.create(user_id: @user.id, quiz_id: @quiz.id)

        end
      end
    else
      render(
          json: {error: "Context is required.", status: 401}
      )
    end
  end

  def quiz_submission_attempt_params
    params.require(:quiz_submission_attempt).permit(:quiz_submission_id, :user_id, :submission_data, :score, :kept_score, :quiz_data, :started_at, :end_at, :finished_at, :workflow_state, :created_by, :updated_by, :fudge_points, :quiz_points_possible, :extra_time, :manually_unlocked, :manually_scored, :score_before_regrade, :was_preview, :has_seen_results, :created_at, :updated_at, :time_spent)
  end
end

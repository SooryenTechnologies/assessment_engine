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
class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable#, :validatable
  has_many :users_permissions
  has_many :question_banks
  has_many :quiz_submissions
  validates_format_of :email, :with  => Devise.email_regexp
  validates :first_name, presence: true
  validates :last_name, presence: true

  # Create instructor for the context.
  def self.create_instructor_or_student(context, first_name, last_name, email, user_id, current_client, role)
    user = User.find_by(first_name: first_name, last_name: last_name, email: email, recieved_user_id: user_id)
    if user.present?
      @user = user
      context.update_attributes(created_by: @user.id, updated_by: @user.id) if !context.created_by.present?
      user_permission = UsersPermission.where(client_id: current_client.id, user_id: @user.id, role: role, context_id: context.id)
      unless user_permission.present?
        user_permission = UsersPermission.create(client_id: current_client.id, user_id: @user.id, role: role, context_id: context.id)
      end
      return {status: "User Created", user: @user}
    else
      @user = User.new(first_name: first_name, last_name: last_name, email: email, recieved_user_id: user_id)
      if @user.save
        context.update_attributes(created_by: @user.id, updated_by: @user.id) if role == "Instructor"
        user_permission = UsersPermission.create(client_id: current_client.id, user_id: @user.id, role: role, context_id: context.id)
        return {status: "User Created", user: @user}
      else
        return {status: "User not", errors: @user.errors }
      end
    end
  end
end

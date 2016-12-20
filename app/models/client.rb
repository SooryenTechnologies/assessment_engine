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
class Client < ActiveRecord::Base
  has_many :users_permissions
  before_create :generate_api_key, :generate_secret_key
  after_create :send_api_mail_to_client
  validates :email, presence: true, uniqueness: true
  validates :client_name, presence: true, uniqueness: true
  validates :password, presence: true

  private
  def generate_api_key
    begin
      self.api_key = SecureRandom.urlsafe_base64(32)
    end while self.class.exists?(api_key: api_key)
  end

  def generate_secret_key
    begin
      self.secret_key = SecureRandom.hex(64)
    end while self.class.exists?(secret_key: secret_key)
  end

  def send_api_mail_to_client
    ClientMailer.api_key_email(self.email, self.client_name, self.api_key).deliver
  end
end

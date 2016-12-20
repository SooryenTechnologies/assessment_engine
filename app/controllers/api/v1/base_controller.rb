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

class Api::V1::BaseController < ApplicationController
  protect_from_forgery with: :null_session

  protected
  # Authenticate Client
  def authenticate_client!
    api_key = request.env["HTTP_X_API_KEY"]

    client = Client.find_by_api_key(api_key)
    if client
      @current_client = client
    else
      return unauthenticated!
    end
  end

  # For Un-Authenticated Client
  def unauthenticated!
    response.headers['WWW-Authenticate'] = "Token realm=Application"
    return api_error(status: 401, errors: 'Bad credentials.')
  end

  # Render the error and status.
  def api_error(status: 500, errors: [])
    unless Rails.env.production?
      puts errors.full_messages if errors.respond_to? :full_messages
    end
    head status: status and return if errors.empty?

    render json: jsonapi_format(errors).to_json, status: status
  end

  # Formating the errors.
  def jsonapi_format(errors)
    errors_hash = { error: [] }
    if errors.try(:messages).present?
      errors.messages.each do |attribute, error|
        array_hash = []
        error.each do |e|
          array_hash << attribute.to_s.split("_").map{|l| l.capitalize}.join(" ") + " " + e
        end
        errors_hash[:error] << { attribute => array_hash }
      end
      return errors_hash
    elsif errors.is_a? String
      return {:error => [errors] }
    else
      return {:error => errors }
    end
  end

end
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
class Api::V1::UserSerializer < ActiveModel::Serializer
  attributes :id

  def created_at
    object.created_at.in_time_zone.iso8601 if object.created_at
  end

  def updated_at
    object.updated_at.in_time_zone.iso8601 if object.created_at
  end
end

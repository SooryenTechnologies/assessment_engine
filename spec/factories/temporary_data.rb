FactoryGirl.define do
  factory :temporary_datum, class: 'TemporaryData' do
    data "MyString"
    user_id 1
    submission_attempt_id 1
  end
end

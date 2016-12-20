# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20161130065010) do

  create_table "active_admin_comments", force: true do |t|
    t.string   "namespace"
    t.text     "body"
    t.string   "resource_id",   null: false
    t.string   "resource_type", null: false
    t.integer  "author_id"
    t.string   "author_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "active_admin_comments", ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id", using: :btree
  add_index "active_admin_comments", ["namespace"], name: "index_active_admin_comments_on_namespace", using: :btree
  add_index "active_admin_comments", ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id", using: :btree

  create_table "admin_users", force: true do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
  end

  add_index "admin_users", ["email"], name: "index_admin_users_on_email", unique: true, using: :btree
  add_index "admin_users", ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true, using: :btree

  create_table "clients", force: true do |t|
    t.string   "client_name"
    t.text     "api_key"
    t.text     "secret_key"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "email"
    t.string   "password"
  end

  create_table "contexts", force: true do |t|
    t.string   "context"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "question_banks", force: true do |t|
    t.string   "title"
    t.integer  "user_id"
    t.integer  "context_id"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "questions", force: true do |t|
    t.text    "name"
    t.text    "question_data"
    t.integer "question_bank_id"
    t.integer "context_id"
  end

  add_index "questions", ["context_id"], name: "index_questions_on_context_id", using: :btree
  add_index "questions", ["question_bank_id"], name: "index_questions_on_question_bank_id", using: :btree

  create_table "quiz_questions", force: true do |t|
    t.integer  "quiz_id"
    t.integer  "question_id"
    t.string   "question_type"
    t.text     "question_data"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "quiz_submission_attempts", force: true do |t|
    t.integer  "quiz_submission_id"
    t.text     "submission_data"
    t.decimal  "score",              precision: 10, scale: 0
    t.datetime "started_at"
    t.datetime "end_at"
    t.datetime "finished_at"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.boolean  "was_preview"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "time_spent",         precision: 10, scale: 0
  end

  create_table "quiz_submissions", force: true do |t|
    t.integer  "quiz_id"
    t.integer  "user_id"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "quizzes", force: true do |t|
    t.string   "title"
    t.text     "description"
    t.integer  "context_id"
    t.string   "resource_link_id"
    t.decimal  "points_possible",              precision: 10, scale: 0
    t.boolean  "shuffle_answers"
    t.boolean  "show_correct_answers"
    t.integer  "time_limit"
    t.integer  "allowed_attempts"
    t.string   "quiz_type"
    t.datetime "lock_at"
    t.datetime "unlock_at"
    t.datetime "due_at"
    t.integer  "question_count"
    t.datetime "published_at"
    t.datetime "last_edited_at"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.string   "hide_results"
    t.boolean  "one_question_at_a_time"
    t.date     "show_correct_answers_at_date"
    t.time     "show_correct_answers_at_time"
    t.date     "hide_correct_answers_at_date"
    t.time     "hide_correct_answers_at_time"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "score_filter"
    t.boolean  "once_after_each_attempt"
    t.boolean  "auto_publish"
    t.boolean  "lock_question_after_answer"
    t.boolean  "time_limit_check"
    t.boolean  "show_quiz_response"
    t.boolean  "allow_multiple_attempt_check"
  end

  create_table "temporary_data", force: true do |t|
    t.text     "data"
    t.integer  "user_id"
    t.integer  "submission_attempt_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: true do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.string   "user_name"
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.string   "auth_token"
    t.string   "recieved_user_id"
  end

  add_index "users", ["auth_token"], name: "index_users_on_auth_token", unique: true, using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

  create_table "users_permissions", force: true do |t|
    t.integer  "client_id"
    t.integer  "user_id"
    t.integer  "context_id"
    t.string   "role"
    t.string   "permission"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end

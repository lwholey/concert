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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20111009130927) do

  create_table "comments", :force => true do |t|
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "email"
  end

  create_table "performers", :force => true do |t|
    t.string   "performer"
    t.string   "you_tube_url"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "results", :force => true do |t|
    t.string   "name"
    t.string   "date_string"
    t.string   "venue"
    t.string   "band"
    t.string   "track_name"
    t.string   "track_spotify"
    t.string   "details_url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.string   "you_tube_url"
  end

  add_index "results", ["user_id"], :name => "index_results_on_user_id"

  create_table "users", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "city"
    t.string   "keywords"
    t.integer  "pageNumber"
    t.integer  "max_pages"
    t.string   "start_date"
    t.string   "end_date"
    t.string   "sort_by"
  end

end

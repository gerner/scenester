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

ActiveRecord::Schema.define(:version => 20110320170947) do

  create_table "event_sources", :force => true do |t|
    t.integer  "event_id"
    t.string   "source"
    t.string   "remote_id"
    t.string   "url"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "events", :force => true do |t|
    t.string   "image"
    t.string   "title"
    t.string   "url"
    t.string   "venue_name"
    t.datetime "start"
    t.datetime "end"
    t.string   "tags"
    t.string   "source"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "venue_id"
    t.string   "source_id"
  end

  create_table "venues", :force => true do |t|
    t.string   "name"
    t.string   "address"
    t.string   "phone"
    t.float    "lat"
    t.float    "long"
    t.string   "url"
    t.string   "map_url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "source"
    t.string   "source_id"
    t.string   "city"
    t.string   "zipcode"
    t.string   "state"
  end

end

# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2025_10_26_133559) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_trgm"
  enable_extension "plpgsql"

  create_table "ingredients", force: :cascade do |t|
    t.string "default_name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["default_name"], name: "index_ingredients_on_default_name", unique: true
    t.index ["default_name"], name: "index_ingredients_on_default_name_trgm", opclass: :gin_trgm_ops, using: :gin
  end

  create_table "recipe_ingredients", force: :cascade do |t|
    t.bigint "ingredient_id", null: false
    t.string "default_name", null: false
    t.string "default_quantity"
    t.decimal "quantity_value", precision: 8, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "unit", default: "unit", null: false
    t.index "lower((default_name)::text)", name: "index_recipe_ingredients_on_lower_default_name", unique: true
    t.index ["default_name"], name: "index_recipe_ingredients_on_default_name_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["ingredient_id"], name: "index_recipe_ingredients_on_ingredient_id"
  end

  create_table "recipe_recipe_ingredients", force: :cascade do |t|
    t.bigint "recipe_id", null: false
    t.bigint "recipe_ingredient_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["recipe_id", "recipe_ingredient_id"], name: "index_rri_on_recipe_and_ingredient", unique: true
    t.index ["recipe_id"], name: "index_recipe_recipe_ingredients_on_recipe_id"
    t.index ["recipe_ingredient_id", "recipe_id"], name: "index_rri_on_ingredient_and_recipe"
    t.index ["recipe_ingredient_id"], name: "index_recipe_recipe_ingredients_on_recipe_ingredient_id"
  end

  create_table "recipes", force: :cascade do |t|
    t.integer "cook_time", default: 0, null: false
    t.integer "prep_time", default: 0, null: false
    t.decimal "rating", precision: 3, scale: 2, default: "0.0", null: false
    t.string "default_title", null: false
    t.string "author"
    t.text "image"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cook_time"], name: "index_recipes_on_cook_time"
    t.index ["default_title"], name: "index_recipes_on_default_title", unique: true
    t.index ["default_title"], name: "index_recipes_on_default_title_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["prep_time"], name: "index_recipes_on_prep_time"
    t.index ["rating"], name: "index_recipes_on_rating"
  end

  add_foreign_key "recipe_ingredients", "ingredients"
  add_foreign_key "recipe_recipe_ingredients", "recipe_ingredients"
  add_foreign_key "recipe_recipe_ingredients", "recipes"
end

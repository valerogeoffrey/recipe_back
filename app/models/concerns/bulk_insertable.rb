# frozen_string_literal: true

module BulkInsertable
  extend ActiveSupport::Concern

  class_methods do
    def bulk_create_ingredients(names)
      new_names = names.select { |name| name.present? && !Ingredient.ingredient_id(name) }
      return if new_names.empty?

      ingredients_to_insert = new_names.map do |name|
        { default_name: name, created_at: Time.current, updated_at: Time.current }
      end

      begin
        Ingredient.insert_all(ingredients_to_insert, unique_by: :default_name)
      rescue ActiveRecord::RecordNotUnique => e
        Rails.logger.warn "[DUPLICATE] Ingredient duplicate: #{e.message}"
      end
    end

    def bulk_create_recipe_ingredients(recipe_id, recipe_ingredients_data)
      return if recipe_ingredients_data.empty?

      ri_to_insert = []
      recipe_ingredients_data.each do |data|
        ingredient_name = data[:ingredient_name]
        ingredient_id = Ingredient.ingredient_id(ingredient_name)

        unless ingredient_id
          Rails.logger.error "[ERROR] Ingredient '#{ingredient_name}' not exist"
          next
        end

        next if RecipeIngredient.recipe_ingredient_exists?(data[:original])

        ri_to_insert << {
          default_name: data[:original],
          ingredient_id: ingredient_id,
          default_quantity: Ingredient.extract_quantity(data[:parsed]),
          quantity_value: Ingredient.extract_amount(data[:parsed]),
          unit: Ingredient.extract_unit(data[:parsed]) || :unit,
          created_at: Time.current,
          updated_at: Time.current
        }
      end

      RecipeIngredient.insert_all(ri_to_insert) if ri_to_insert.any?

      original_queries = recipe_ingredients_data.pluck(:original)
      recipe_ingredient_ids = RecipeIngredient.where(default_name: original_queries).pluck(:id)

      rri_to_insert = recipe_ingredient_ids.map do |ri_id|
        { recipe_id: recipe_id, recipe_ingredient_id: ri_id, created_at: Time.current, updated_at: Time.current }
      end

      RecipeRecipeIngredient.insert_all(rri_to_insert) if rri_to_insert.any?
    end
  end
end

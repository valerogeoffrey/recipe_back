# frozen_string_literal: true

module Ingredients
  module Parsable
    extend ActiveSupport::Concern

    class_methods do
      def parse(ingredient_string, config: { enable_fallback: true })
        result = parse_with_ingreedy(ingredient_string)
        return Result.success(result) if result

        result = parse_with_food_parser(ingredient_string)
        return Result.success(result) if result

        if config[:enable_fallback]
          result = parse_with_fallback(ingredient_string)
          return Result.success(result) if result
        end

        Result.failed("Unable to parse ingredient: #{ingredient_string}")
      rescue StandardError => e
        Result.failed("Parsing error: #{e.message}")
      end

      def extract_ingredient_name(parsed)
        return nil unless parsed

        if parsed.respond_to?(:ingredient)
          parsed.ingredient&.to_s&.strip
        elsif parsed.is_a?(Hash)
          parsed[:ingredient]&.to_s&.strip
        end
      end

      def extract_quantity(parsed_ingredient)
        return nil unless parsed_ingredient.respond_to?(:amount) || parsed_ingredient.respond_to?(:unit)

        amount = parsed_ingredient.respond_to?(:amount) ? parsed_ingredient.amount : nil
        unit = parsed_ingredient.respond_to?(:unit) ? parsed_ingredient.unit : nil
        return nil unless amount || unit

        [amount, unit].compact.join(' ')
      end

      def extract_unit(parsed)
        return :unit unless parsed.respond_to?(:unit) && parsed.respond_to?(:container_unit)
        return parsed.unit if parsed.respond_to?(:unit)
        return parsed.container_unit if parsed.respond_to?(:container_unit)

        :unit
      end

      def extract_amount(parsed)
        parsed.respond_to?(:amount) ? parsed.amount : nil
      end

      private

      def parse_with_ingreedy(ingredient_string)
        parsed = Ingreedy.parse(ingredient_string)
        return nil unless parsed&.ingredient

        parsed
      rescue Ingreedy::ParseFailed, StandardError
        nil
      end

      def parse_with_food_parser(ingredient_string)
        parsed = FoodIngredientParser.parse(ingredient_string)
        return nil unless parsed&.ingredient

        parsed
      rescue StandardError
        nil
      end

      def parse_with_fallback(ingredient_string)
        # Simple fallback: extract the ingredient name from the string
        # Remove common quantity patterns
        cleaned = ingredient_string.to_s.strip
        cleaned = cleaned.gsub(%r{^\d+[\d\s/.,]*\s*}, '') # Remove leading numbers
        cleaned = cleaned.gsub(/^(cup|cups|teaspoon|teaspoons|tbsp|tablespoon|tablespoons|ounce|ounces|oz|gram|grams|g|kg|pound|pounds|lb|lbs|can|cans|package|packages|slice|slices|clove|cloves|pint|pints|quart|quarts|liter|liters|ml|dl)s?\s+/i, '') # Remove units

        return nil if cleaned.blank?

        OpenStruct.new(ingredient: cleaned, amount: nil, unit: nil)
      end
    end
  end
end

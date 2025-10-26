# frozen_string_literal: true

require 'ostruct'
require 'json'
require 'bigdecimal'
require 'ingreedy'
require 'active_support/inflector'

namespace :recipes do
  desc 'Normalize Recipes data and populate DB (optimized)'
  task :normalize, [:limit] => :environment do |_t, args|
    Recipes::Normalize.reset_logger
    logger = Recipes::Normalize.logger

    file_path = Rails.public_path.join('recipes.json')
    json_conf = File.read(file_path)
    parsed = JSON.parse(json_conf)

    limit = args[:limit]&.to_i || 1_000_000_000
    limit = 1_000_000_000 if limit.present? && limit <= 0
    parsed = parsed.first(limit)

    logger.info '=' * 80
    logger.info 'STARTING MIGRATION'
    logger.info '=' * 80
    logger.info "Total recipes to process: #{parsed.size}"
    logger.info "Limit applied: #{args[:limit] || 'none'}"
    start_time = Time.current
    success_count = 0
    failure_count = 0
    batch_size = APP_CONF.dig(:normalization, :batch) || 100
    total_batches = (parsed.size / batch_size.to_f).ceil

    logger.info "Batch size: #{batch_size}"
    logger.info "Total batches: #{total_batches}"

    parsed.each_slice(batch_size).with_index do |batch, batch_idx|
      logger.info "Processing batch #{batch_idx + 1}/#{total_batches}"
      batch_results = Recipes::Normalize.call(batch)

      batch_results.each_with_index do |result, idx|
        recipe_idx = (batch_idx * batch_size) + idx
        recipe = parsed[recipe_idx]

        if result.success?
          success_count += 1
          print "\e[32m.\e[0m"
        else
          failure_count += 1
          print "\e[31m.\e[0m"
          logger.error "[FAILED] Recipe ##{recipe_idx + 1}: #{recipe['title']}"
          logger.error "  └─ Error: #{result.message}" if result.respond_to?(:message)
        end
      end
    end

    duration = Time.current - start_time
    success_rate = ((success_count.to_f / parsed.size) * 100).round(2)

    puts "\n\n#{'=' * 50}"
    puts 'Migration completed!'
    puts '=' * 50
    puts "Total recipes processed: #{parsed.size}"
    puts "✓ Success: #{success_count}"
    puts "✗ Failed: #{failure_count}"
    puts "Duration: #{duration.round(2)} seconds"
    puts "Average: #{(parsed.size / duration).round(2)} recipes/second"
    puts "Success rate: #{success_rate}%"
    puts '=' * 50

    logger.stats(
      'Total processed' => parsed.size,
      'Success' => success_count,
      'Failed' => failure_count,
      'Duration' => "#{duration.round(2)}s",
      'Throughput' => "#{(parsed.size / duration).round(2)} recipes/s",
      'Success rate' => "#{success_rate}%"
    )

    logger.close
  end

  task reset_data: :environment do
    puts 'Start flush tables'

    RecipeRecipeIngredient.delete_all
    RecipeIngredient.delete_all
    Ingredient.delete_all
    Recipe.delete_all
    puts 'Flush tables successfully ended'
  end
end

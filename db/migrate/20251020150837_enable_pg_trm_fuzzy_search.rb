# frozen_string_literal: true

class EnablePgTrmFuzzySearch < ActiveRecord::Migration[7.1]
  # Usefull for GIN index - fuzzy search
  def up
    enable_extension 'pg_trgm' unless extension_enabled?('pg_trgm')
  end

  def down
    disable_extension 'pg_trgm' if extension_enabled?('pg_trgm')
  end
end

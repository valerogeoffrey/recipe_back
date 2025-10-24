ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.

# Load dotenv before anything else
require 'dotenv/load'

require "bootsnap/setup" # Speed up boot time by caching expensive operations.

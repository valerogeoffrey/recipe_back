Kaminari.configure do |config|
  config.default_per_page = APP_CONF[:api][:pagination][:default_per_page]
  config.max_per_page = APP_CONF[:api][:pagination][:max_per_page]
end

# Rails.root is not yet defined
APP_CONF ||= begin
  root_path = Rails::Application.find_root(__FILE__)

  conf = ActiveSupport::HashWithIndifferentAccess.new(YAML.load(ERB.new(IO.read(root_path.join('config', 'app_conf.yml'))).result(binding)))

  raise "Missing conf for #{Rails.env}. Does #{Rails.env} key exists in config/app_conf.yml?" unless conf[Rails.env]

  conf[:default].deep_merge(conf[Rails.env])
end

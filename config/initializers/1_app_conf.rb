# Rails.root is not yet defined
# /!\ TODO /!\
# It will be better to follow the rails guidelines to inject conf into app => https://guides.rubyonrails.org/configuring.html#custom-configuration
# Need some refacto in initializers file but is highly recommended to do it before going to kubernetes
APP_CONF ||= begin
  root_path = Rails::Application.find_root(__FILE__)

  conf = ActiveSupport::HashWithIndifferentAccess.new(YAML.load(ERB.new(IO.read(root_path.join('config', 'app_conf.yml'))).result(binding)))

  raise "Missing conf for #{Rails.env}. Does #{Rails.env} key exists in config/app_conf.yml?" unless conf[Rails.env]

  conf[:default].deep_merge(conf[Rails.env])
end

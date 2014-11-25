require 'yaml'

ARTFULLY_CONFIG = HashWithIndifferentAccess.new(YAML.load_file("#{Rails.root.to_s}/config/artfully.yml")[Rails.env])
#!/usr/bin/env gem build
# encoding: utf-8

$:.push File.expand_path("../lib", __FILE__)

require "artfully_ose/version"

Gem::Specification.new do |s|
  s.name        = "artfully_ose"
  s.version     = ArtfullyOse::VERSION
  s.authors     = ["Artful.ly"]
  s.email       = ["support@artful.ly"]
  s.homepage    = "http://fracturedatlas.github.com/artfully_ose/"
  s.summary     = "A Ruby on Rails engine for running ticketing, CRM, and order management"
  s.description = "A Ruby on Rails engine for running ticketing, CRM, and order management.  See http://fracturedatlas.github.com/artfully_app/ for the reference implementation"

  s.files = Dir["{app,config,db,lib}/**/*", "spec/factories/**/*", "LICENSE.txt", "Rakefile", "README.md"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", ">= 3.2.12"
  s.add_dependency "transitions", "0.0.11"
  s.add_dependency "devise", "=2.0.5"
  s.add_dependency "devise_invitable", "=1.0.2"
  s.add_dependency "devise_suspendable", "=0.6.1"

  s.add_dependency "active_model_serializers", "=0.6.0"
  s.add_dependency "exceptional", ">= 2.0.33"
  s.add_dependency "slugged", "1.1.0"

  s.add_dependency "activemerchant", "~> 1.43.0"
  s.add_dependency "braintree", "~> 2.13.0"

  s.add_dependency "delayed_job", "=3.0.2"
  s.add_dependency "delayed_job_active_record", "=0.3.2"
  s.add_dependency "audited-activerecord", "~> 3.0"
  s.add_dependency "activerecord-import", "0.2.9"
  s.add_dependency "acts-as-taggable-on", "~>2.3.3"
  s.add_dependency "haml", "~> 3.1"
  s.add_dependency "sass", "3.3.5"
  # s.add_dependency "font-awesome-sass", "4.0.3.1"

  s.add_dependency "will_paginate", '~> 3.0'
  s.add_dependency "bootstrap-will_paginate"

  s.add_dependency "aws-sdk", "~> 1.34.1"
  s.add_dependency "paperclip", '~> 3.5.2'
  s.add_dependency "comma", '3.0.3'
  s.add_dependency "text-table", '1.2.2'

  s.add_dependency "s3", '>= 0.3.11'
  s.add_dependency "validates_timeliness"
  s.add_dependency "sunspot_rails", "1.3.3"
  s.add_dependency "gravatar_image_tag"
  s.add_dependency "cancan", "1.6.7"
  s.add_dependency "dynamic_form", "1.1.4"
  s.add_dependency "mail", "2.4.4"
  s.add_dependency "gibbon", "0.3.5"
  s.add_dependency "set_watch_for", "0.0.1"
  s.add_dependency "swiper", "0.0.3"

  s.add_dependency "uuid", "2.3.5"

  #Macaddr had a problem in 1.6.2 so lock to 1.6.1
  s.add_dependency "macaddr", "1.6.1" 
  s.add_dependency "geocoder"
  s.add_dependency "slicer", "0.0.2"

  s.add_dependency "rqrcode_png", "0.1.1"
  s.add_development_dependency "sunspot_solr", "1.3.3"
end

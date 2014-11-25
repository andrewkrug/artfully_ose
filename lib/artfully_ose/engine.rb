module ArtfullyOse
  class Engine < ::Rails::Engine

    if Rails.env.test?
      initializer 'artfully_ose.factories', :after => 'factory_girl.set_factory_paths' do
        puts 'ArtfullyOse: Setting up additional FactoryGirl paths'
        FactoryGirl.definition_file_paths << File.expand_path('../../../spec/factories', __FILE__) if defined?(FactoryGirl)
      end
    end

    initializer "artfully_ose.braintree_config" do |app|
      puts "ArtfullyOse: Initializing Braintree config"
      BraintreeConfig      = Struct.new(:merchant_account_id, :merchant_id, :public_key, :private_key)
      app.config.braintree = BraintreeConfig.new
      app.config.braintree.merchant_account_id = ENV['BRAINTREE_MERCHANT_ACCOUNT_ID']
      app.config.braintree.merchant_id         = ENV['BRAINTREE_MERCHANT_ID']
      app.config.braintree.public_key          = ENV['BRAINTREE_PUBLIC_KEY']
      app.config.braintree.private_key         = ENV['BRAINTREE_PRIVATE_KEY']
    end
    
    initializer "artfully_ose.s3_config" do |app|
      puts "ArtfullyOse: Initializing S3 config"
      S3Config = Struct.new(:bucket, :access_key_id, :secret_access_key)
      app.config.s3 = S3Config.new
      app.config.s3.bucket               = ENV['S3_BUCKET']
      app.config.s3.access_key_id        = ENV['S3_ACCESS_KEY_ID']
      app.config.s3.secret_access_key    = ENV['S3_SECRET_ACCESS_KEY']
    end
    
    initializer "artfully_ose.payment_model_paths" do |app|
      puts "ArtfullyOse: Initializing payment model paths"
      puts config.root
      app.config.payment_model_paths       = []
      app.config.payment_model_paths      += Dir["#{config.root}/app/models/payments/*.rb"]
    end
    
    initializer "artfully_ose.discount_type_paths" do |app|
      puts "ArtfullyOse: Initializing discount types"
      app.config.discount_type_paths       = []
      app.config.discount_type_paths      += Dir["#{config.root}/app/models/discounts/*.rb"]
    end
    
    initializer "artfully_ose.google_analytics_config" do |app|
      puts "ArtfullyOse: Initializing Google Analytics config"
      GoogleAnalytcsConfig = Struct.new(:account, :storefront_account, :domain)
      app.config.google_analytics                       = GoogleAnalytcsConfig.new
      app.config.google_analytics.account               = ENV['GA_ACCOUNT']
      app.config.google_analytics.storefront_account    = ENV['GA_STOREFRONT_ACCOUNT']
      app.config.google_analytics.domain                = ENV['GA_DOMAIN']
    end
   
    initializer "artfully_ose.autoload_paths", :before => :set_autoload_paths do |app|
      # First level sub-directories only
      model_paths = [
        "#{config.root}/app/models/actions",
        "#{config.root}/app/models/database_views",
        "#{config.root}/app/models/discounts",
        "#{config.root}/app/models/imports",
        "#{config.root}/app/models/job",
        "#{config.root}/app/models/kits",
        "#{config.root}/app/models/orders",
        "#{config.root}/app/models/payments",
      ]

      puts "ArtfullyOse: Setting up additional autoload paths"
      app.config.autoload_paths += model_paths

    end

    config.generators do |g|
      g.test_framework :rspec, :view_specs => false
    end

    config.autoload_paths += %W(
      #{config.root}/app/models/concerns
    )
  end
end
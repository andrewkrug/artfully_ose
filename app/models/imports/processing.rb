module Imports
  module Processing
    def self.included(base)
      base.class_eval do  
        attr_accessible :s3_bucket, :s3_key, :s3_etag      
        belongs_to :user
        belongs_to :organization
        
        validates_presence_of :user
        validates_associated  :user
        validates_presence_of :s3_bucket
        validates_presence_of :s3_key
        validates_presence_of :s3_etag
      end
    end

    #
    # TODO: This should absolutely be moved into organization.rb
    #
    def time_zone_parser
      @parser ||= ActiveSupport::TimeZone.create(self.organization.time_zone)
      @parser
    end

    def csv_data
      return @csv_data if @csv_data
    
      @csv_data =
        if File.file?(self.s3_key)
          File.read(self.s3_key)
        else
          s3_bucket = s3_service.buckets.find(self.s3_bucket) if self.s3_bucket.present?
          s3_object = s3_bucket.objects.find(self.s3_key) if s3_bucket
          s3_object.content(true) if s3_object
        end

      # Make sure the csv file is valid utf-8.
      if @csv_data
        @csv_data.encode! "UTF-8", :invalid => :replace, :undef => :replace, :replace => ""
        @csv_data = @csv_data.chars.map { |c| c if c.valid_encoding? }.compact.join
      end

      @csv_data
    end

    def s3_service
      access_key_id     = Rails.application.config.s3.access_key_id
      secret_access_key = Rails.application.config.s3.secret_access_key

      S3::Service.new(:access_key_id => access_key_id, :secret_access_key => secret_access_key)
    end
  end
end
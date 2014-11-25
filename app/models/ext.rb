module Ext
  #
  # Includers will have a uuid generated for them before_create
  # Method self.multi_find can be used to find by either id or uuid
  #
  # Requires a :uuid column on the including class
  # 
  module Uuid
    
    #Required to prevent Ruby from parsing uuid's with leading digits into a primary key id
    PREFIX = "art-"

    def self.included(base)
      base.class_eval do
        before_create :set_uuid
      end
      base.extend ClassMethods
    end

    module ClassMethods
      def multi_find(key, includes = [])
        arel = self.arel_table
        where(arel[:id].eq(key).or(arel[:uuid].eq(key))).includes(includes).first
      end
    end
    
    def set_uuid
      if self.uuid.nil?
        self.uuid = PREFIX + SecureRandom.uuid
      end
    end
    
    def self.uuid
      PREFIX + SecureRandom.uuid
    end
  end

  module S3Link
    def download_link_for(field)
      s3 = AWS::S3.new(
          :access_key_id     => ENV['S3_ACCESS_KEY_ID'],
          :secret_access_key => ENV['S3_SECRET_ACCESS_KEY']
      )
      bucket = s3.buckets[ENV['S3_BUCKET']]
      object = bucket.objects[self.send(field).path]
      url    = object.url_for(:read, :expires => 10*60)
      url.to_s
    end
  end
end
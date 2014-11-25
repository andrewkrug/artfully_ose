#
# The attachment's attachee must have a uuid column to use this
#
Paperclip.interpolates :uuid do |attachment, style|
  attachment.instance.uuid
end

if Rails.env.test?
  TICKET_QR_STORAGE = {} # default
else
  TICKET_QR_STORAGE = {
    :storage => :s3,
    :path => ":attachment/:id/:style.:extension",
    :bucket => Rails.configuration.s3.bucket,
    :s3_protocol => 'https',
    :s3_credentials => {
      :access_key_id => Rails.configuration.s3.access_key_id,
      :secret_access_key => Rails.configuration.s3.secret_access_key
    }
  }
end

if Rails.env.test?
  ORDER_PDF_STORAGE = {} # default
else
  ORDER_PDF_STORAGE = {
    :storage => :s3,
    :path => ":attachment/orders/:id/:style.:extension",
    :bucket => Rails.configuration.s3.bucket,
    :s3_protocol => 'https',
    :s3_permissions => 'private',
    :s3_credentials => {
      :access_key_id => Rails.configuration.s3.access_key_id,
      :secret_access_key => Rails.configuration.s3.secret_access_key
    }
  }
end

if Rails.env.test?
  MEMBER_QR_STORAGE = {} # default
else
  MEMBER_QR_STORAGE = {
    :storage => :s3,
    :path => ":attachment/members/:id/:style.:extension",
    :bucket => Rails.configuration.s3.bucket,
    :s3_protocol => 'https',
    :s3_permissions => 'private',
    :s3_credentials => {
      :access_key_id => Rails.configuration.s3.access_key_id,
      :secret_access_key => Rails.configuration.s3.secret_access_key
    }
  }
end

if Rails.env.test?
  MEMBER_PDF_STORAGE = {} # default
else
  MEMBER_PDF_STORAGE = {
    :storage => :s3,
    :path => ":attachment/members/:uuid/membership_card.pdf",
    :bucket => Rails.configuration.s3.bucket,
    :s3_protocol => 'https',
    :s3_permissions => 'private',
    :s3_credentials => {
      :access_key_id => Rails.configuration.s3.access_key_id,
      :secret_access_key => Rails.configuration.s3.secret_access_key
    }
  }
end
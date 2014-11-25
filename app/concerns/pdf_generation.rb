require 'json'
require 'digest/md5'

class PdfGeneration
  PDF_POST_URL     = "http://quick-pdf.geminisbs.net/pdfs.json"
  PDF_GET_URL      = "http://quick-pdf.geminisbs.net/pdfs/:id.json?api_key=:key"
  PDF_DOWNLOAD_URL = "http://quick-pdf.geminisbs.net/pdfs/:id/download?api_key=:key"

  attr_accessor :pdf_options

  def initialize(pdfable, pdf_api_key = PDF_API_KEY, http_party = HTTParty, sleeper = Kernel)
    @pdfable      = pdfable
    @pdf_api_key  = pdf_api_key
    @http_party   = http_party
    @sleeper      = sleeper
    @pdf_options  = {}
  end

  def generate
    Wisepdf::Writer.new.to_pdf(content)
  end

  def content
    file_name   = pdfable.class.name.underscore
    file_name   = 'order' if file_name.ends_with?('order')
    template    = File.read("#{ArtfullyOse::Engine.root}/app/views/pdfs/#{file_name}.html.haml")
    haml_engine = Haml::Engine.new(template)
    scope       = Object.new.extend(ArtfullyOseHelper)
    output      = haml_engine.render(scope, {:pdfable => pdfable})
    output.gsub("'","\'") # necessary to escape single '
  end

  private
  attr_reader :pdfable, :pdf_api_key, :http_party, :sleeper
  def pdf_attributes
    {
      :body => {
        :api_key => pdf_api_key,
        :pdf => {
          :html_doc => content,
          :filename => filename,
          :pdf_options => {
            :margin_top => "0.5in",
            :margin_bottom => "0.5in",
            :margin_left => "0.5in",
            :margin_right => "0.5in"
          }.merge(pdf_options)
        }
      }
    }
  end

  def filename
    "#{Digest::MD5.hexdigest pdfable.id.to_s}.pdf"
  end

  def status_url(json)
    PDF_GET_URL.gsub(":id", json["id"].to_s).gsub(":key", pdf_api_key)
  end

  def download_url(json)
    PDF_DOWNLOAD_URL.gsub(":id", json["id"].to_s).gsub(":key", pdf_api_key)
  end
end

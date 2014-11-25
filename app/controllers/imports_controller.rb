class ImportsController < ArtfullyOseController

  before_filter { authorize! :create, Import }
  before_filter :set_import_type

  def index
    @imports = organization.imports.includes(:user, :organization).order('created_at desc').all
    @sales_csv_download_link, @donations_csv_download_link = download_links
  end

  def approve
    @import = organization.imports.find(params[:id])
    @import.approve!

    flash[:notice] = "Your file has been entered in the import queue. This process may take some time.  Reload this page to see progress or check back in a few minutes."
    redirect_to imports_path
  end

  def show
    @import = organization.imports.find(params[:id])

    #
    # Building an import preview was just murdering us. The problem is way down in Array.index in parsed_row.load_value.
    # Temporarily shutting it off for > 1000
    #
    if @import.status == "pending"
      @imported_rows    = @import.import_rows.paginate(:page => params[:page], :per_page => 50)
    end

    @people   = Person.where(:import_id => @import.id).paginate(:page => params[:page], :per_page => 50) unless @import.id.nil?
    @messages = ImportMessage.where(:import_id => @import.id).paginate(:page => params[:messages_page], :per_page => 10) unless @import.id.nil?
  end

  def new
    if params[:bucket].present? && params[:key].present?      
      @import = Import.build(@type)
      @import.organization  = organization
      @import.s3_bucket     = params[:bucket]
      @import.s3_key        = params[:key]
      @import.s3_etag       = params[:etag]
      @import.status        = "caching"
      @import.user_id       = current_user.id
      @import.caching!
      redirect_to import_path(@import)
    else
      @import = Import.build(@type)
    end
  end

  def create
    @import = Import.build(@type)
    @import.user = current_user
    @import.organization = organization

    if @import.save
      redirect_to import_path(@import)
    else
      render :new
    end
  end

  def destroy
    @import = organization.imports.find(params[:id])
    @import.destroy
    redirect_to imports_path
  end

  def template   
    case @type
    when "events"
      fields = ParsedRow::EVENT_FIELDS.merge(ParsedRow::PEOPLE_FIELDS).merge(ParsedRow::ADDRESS_FIELDS)
    when "people"
      fields = ParsedRow::PEOPLE_FIELDS.merge(ParsedRow::ADDRESS_FIELDS)
    when "donations"
      fields = ParsedRow::DONATION_FIELDS.merge(ParsedRow::PEOPLE_FIELDS).merge(ParsedRow::ADDRESS_FIELDS)
    else
      raise "Unknown import type."
    end
    
    columns = fields.map { |field, names| names.first }
    csv_string = CSV.generate { |csv| csv << columns }
    send_data csv_string, :filename => "Artfully-Import-Template.csv", :type => "text/csv", :disposition => "attachment"
  end

  def recall
    @import = organization.imports.find(params[:id])
    raise "Can't recall imports other than people imports." unless @import.is_a?(PeopleImport)

    Delayed::Job.enqueue RecallImportJob.new(@import.id)
    flash[:notice] = "The import is currently being recalled. Reload this page to see progress or check back in a few minutes."
    redirect_to imports_path
  end

  protected

    def organization
      current_user.current_organization
    end
    
    def set_import_type
      #Cache import type to work around the direct to s3 upload
      session[:type] = params[:type] unless params[:type].blank?
      @type = (params[:type] || session[:type])
    end

    def download_links
      s3 = AWS::S3.new(
          :access_key_id     => ENV['S3_ACCESS_KEY_ID'],
          :secret_access_key => ENV['S3_SECRET_ACCESS_KEY']
      )
      bucket = s3.buckets[ENV['S3_BUCKET']]
      object = bucket.objects[ItemView.sales_export_filename_for(current_organization)]
      url    = object.url_for(:read, :expires => 10*60)
      sales_link = url.to_s

      bucket = s3.buckets[ENV['S3_BUCKET']]
      object = bucket.objects[ItemView.donations_export_filename_for(current_organization)]
      url    = object.url_for(:read, :expires => 10*60)
      donations_link = url.to_s

      [sales_link, donations_link]
    end

end

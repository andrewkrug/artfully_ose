class PassesReportsController < ArtfullyOseController
  def index
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    @organization = current_user.current_organization
    @pass_types = @organization.pass_types
    @pass_type = PassType.find(params[:pass_type]) if params[:pass_type].present?
    @report = nil
    @report = PassesReport.new(@organization, @pass_type, @start_date, @end_date)
    @rows = @report.rows.paginate(:page => params[:page], :per_page => 100) unless @report.nil?

    @options_for_select = @pass_types.collect{ |p| [p.name, p.id] }
    @options_for_select.unshift [PassType::ALL_PASSES_STRING, nil]

    respond_to do |format|
      format.html

      format.csv do
        @filename = [ @report.header, ".csv" ].join
        @csv_string = @report.rows.to_comma
        send_data @csv_string, :filename => @filename, :type => "text/csv", :disposition => "attachment"
      end
    end
  end
end
class DiscountsReportsController < ArtfullyOseController
  def index
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    @organization = current_user.current_organization
    @codes = Discount.unique_codes_for(current_user.current_organization)
    code = (params[:code]==Discount::ALL_DISCOUNTS_STRING ? nil : params[:code])
    @report = nil
    @report = DiscountsReport.new(@organization, code, @start_date, @end_date) unless params[:code].nil?
    @rows = @report.rows.paginate(:page => params[:page], :per_page => 100) unless @report.nil?

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
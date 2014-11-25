class ExportController < ArtfullyOseController

  def contacts
    @organization = current_user.current_organization
    @filename = "Artfully-People-Export-#{DateTime.now.strftime("%m-%d-%y")}.csv"
    @csv_string = @organization.people.includes(:tags, :phones, :address).all.to_comma
    send_data @csv_string, :filename => @filename, :type => "text/csv", :disposition => "attachment"
  end

  #
  # Artful.ly generates these nightly and provides links directly to s3
  #
  def donations
    @organization = current_user.current_organization
    @filename = "Artfully-Donations-Export-#{DateTime.now.strftime("%m-%d-%y")}.csv"
    @items = ItemView.where(:organization_id => current_organization).where(:product_type => "Donation").all
    @csv_string = @items.to_comma(:donation)  
    send_data @csv_string, :filename => @filename, :type => "text/csv", :disposition => "attachment"
  end

  #
  # Artful.ly generates these nightly and provides links directly to s3
  #
  def ticket_sales
    @organization = current_user.current_organization
    @filename = "Artfully-Ticket-Sales-Export-#{DateTime.now.strftime("%m-%d-%y")}.csv"
    @items = ItemView.where(:organization_id => current_organization).where(:product_type => "Ticket").all
    @csv_string = @items.to_comma(:ticket_sale)    
    send_data @csv_string, :filename => @filename, :type => "text/csv", :disposition => "attachment"
  end

end
